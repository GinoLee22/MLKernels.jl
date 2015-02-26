#===================================================================================================
  Auxiliary Functions
===================================================================================================#

# Symmetrize the lower half of matrix S using the upper half of S
function syml!(S::Matrix)
    p = size(S, 1)
    p == size(S, 2) || error("S ∈ ℝ$(p)×$(size(S, 2)) should be square")
    if p > 1 
        for j = 1:(p - 1) 
            for i = (j + 1):p 
                S[i, j] = S[j, i]
            end
        end
    end
    return S
end
syml(S::Matrix) = syml!(copy(S))


#===================================================================================================
  Kernel Matrix Functions
===================================================================================================#

# Returns the kernel (Gramian) matrix K of data matrix X for mapping ϕ
function kernel_matrix{T<:FloatingPoint}(X::Matrix{T}, κ::Kernel = LinearKernel(), sym::Bool = true)
    k = kernel_function(κ)
    n = size(X, 1)
    K = Array(T, n, n)
    for i = 1:n 
        for j = i:n
            K[i,j] = k(X[i,:], X[j,:])  # @inbounds?
        end 
    end
    sym ? syml!(K) : K
end

# Returns the upper right corner kernel (Gramian) matrix K of data matrix [Xᵗ,Zᵗ]ᵗ
function kernel_matrix{T<:FloatingPoint}(X::Matrix{T}, Z::Matrix{T}, κ::Kernel = LinearKernel())
    k = kernel_function(κ)
    n = size(X, 1)
    m = size(Z, 1)
    size(X, 2) == size(Z, 2) || error("X ∈ ℝn×p and Z should be ∈ ℝm×p, but X ∈ " * (
                                      "ℝn×$(size(X, 2)) and Z ∈ ℝm×$(size(Z, 2))."))
    K = Array(T, n, m)
    for j = 1:m 
        for i = 1:n
            K[i,j] = k(X[i,:], Z[j,:])  # @inbounds?
        end
    end
    return K
end

# Centralize a kernel matrix K
function center_kernel_matrix!{T<:FloatingPoint}(K::Matrix{T})
	n = size(K, 1)
	n == size(K, 2) || error("Kernel matrix must be square")
	row_mean = sum(K, 1)
	element_mean = sum(row_mean) / (convert(T, n)^2)
	BLAS.scal!(n, one(T)/convert(T,n), row_mean, 1)
	((K .- row_mean) .- row_mean') .+ element_mean
end
center_kernel_matrix{T<:FloatingPoint}(K::Matrix{T}) = center_kernel_matrix!(copy(K))


#===================================================================================================
  Kernel Matrix Functions
===================================================================================================#

function init_approx{T<:FloatingPoint}(X::Matrix{T}, Sample::Array{Int}, kernel::MercerKernel = LinearKernel())
    k = kernelfunction(kernel)
    c = length(Sample)
    n = size(X, 1)
    Cᵗ = Array(T, n, c)
    for i = 1:n
        for j = 1:c
            Cᵗ[i,j] = k(X[i,:], X[Sample[j],:])
        end
    end
    W = pinv(Cᵗ[Sample,:])
    return Cᵗ * W * Cᵗ'
end
