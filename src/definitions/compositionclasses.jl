#==========================================================================
  Composition Classes
==========================================================================#

#== Positive Mercer Classes ==#

abstract PositiveMercerClass{T<:AbstractFloat} <: CompositionClass{T}

doc"GammaExponentialClass(κ;α,γ) = exp(-α⋅κᵞ)"
immutable GammaExponentialClass{T<:AbstractFloat} <: PositiveMercerClass{T}
    alpha::Parameter{T}
    gamma::Parameter{T}
    GammaExponentialClass(α::Variable{T}, γ::Variable{T}) = new(
        Parameter(α, LowerBound(zero(T), :strict)),
        Parameter(γ, Interval(Bound(zero(T), :strict), Bound(one(T), :nonstrict)))
    )
end
@outer_constructor(GammaExponentialClass, (1,0.5))
@inline iscomposable(::GammaExponentialClass, κ::Kernel) = isnegdef(κ) && isnonnegative(κ)
@inline phi{T<:AbstractFloat}(ϕ::GammaExponentialClass{T}, z::T) = exp(-ϕ.alpha * z^ϕ.gamma)


doc"ExponentialClass(κ;α) = exp(-α⋅κ²)"
immutable ExponentialClass{T<:AbstractFloat} <: PositiveMercerClass{T}
    alpha::Parameter{T}
    ExponentialClass(α::Variable{T}) = new(
        Parameter(α, LowerBound(zero(T), :strict))
    )
end
@outer_constructor(ExponentialClass, (1,))
@inline iscomposable(::ExponentialClass, κ::Kernel) = isnegdef(κ) && isnonnegative(κ)
@inline phi{T<:AbstractFloat}(ϕ::ExponentialClass{T}, z::T) = exp(-ϕ.alpha * z)


doc"GammaRationalClass(κ;α,β,γ) = (1 + α⋅κᵞ)⁻ᵝ"
immutable GammaRationalClass{T<:AbstractFloat} <: PositiveMercerClass{T}
    alpha::Parameter{T}
    beta::Parameter{T}
    gamma::Parameter{T}
    GammaRationalClass(α::Variable{T}, β::Variable{T}, γ::Variable{T}) = new(
        Parameter(α, LowerBound(zero(T), :strict)),
        Parameter(β, LowerBound(zero(T), :strict)),
        Parameter(γ, Interval(Bound(zero(T), :strict), Bound(one(T), :nonstrict)))
    )
end
@outer_constructor(GammaRationalClass, (1,1,0.5))
@inline iscomposable(::GammaRationalClass, κ::Kernel) = isnegdef(κ) && isnonnegative(κ)
@inline phi{T<:AbstractFloat}(ϕ::GammaRationalClass{T}, z::T) = (1 + ϕ.alpha*z^ϕ.gamma)^(-ϕ.beta)


doc"RationalClass(κ;α,β,γ) = (1 + α⋅κ)⁻ᵝ"
immutable RationalClass{T<:AbstractFloat} <: PositiveMercerClass{T}
    alpha::Parameter{T}
    beta::Parameter{T}
    RationalClass(α::Variable{T}, β::Variable{T}) = new(
        Parameter(α, LowerBound(zero(T), :strict)),
        Parameter(β, LowerBound(zero(T), :strict))
    )
end
@outer_constructor(RationalClass, (1,1))
@inline iscomposable(::RationalClass, κ::Kernel) = isnegdef(κ) && isnonnegative(κ)
@inline phi{T<:AbstractFloat}(ϕ::RationalClass{T}, z::T) = (1 + ϕ.alpha*z)^(-ϕ.beta)


doc"MatérnClass(κ;ν,ρ) = 2ᵛ⁻¹(√(2ν)κ/ρ)ᵛKᵥ(√(2ν)κ/ρ)/Γ(ν)"
immutable MaternClass{T<:AbstractFloat} <: PositiveMercerClass{T}
    nu::Parameter{T}
    rho::Parameter{T}
    MaternClass(ν::Variable{T}, ρ::Variable{T}) = new(
        Parameter(ν, LowerBound(zero(T), :strict)),
        Parameter(ρ, LowerBound(zero(T), :strict))
    )
end
@outer_constructor(MaternClass, (1,1))
@inline iscomposable(::MaternClass, κ::Kernel) = isnegdef(κ) && isnonnegative(κ)
@inline function phi{T<:AbstractFloat}(ϕ::MaternClass{T}, z::T)
    v1 = sqrt(2ϕ.nu) * z / ϕ.rho
    v1 = v1 < eps(T) ? eps(T) : v1  # Overflow risk, z -> Inf
    2 * (v1/2)^(ϕ.nu) * besselk(ϕ.nu, v1) / gamma(ϕ.nu)
end


doc"ExponentiatedClass(κ;α) = exp(a⋅κ + c)"
immutable ExponentiatedClass{T<:AbstractFloat} <: PositiveMercerClass{T}
    a::Parameter{T}
    c::Parameter{T}
    ExponentiatedClass(a::Variable{T}, c::Variable{T}) = new(
        Parameter(a, LowerBound(zero(T), :strict)),
        Parameter(c, LowerBound(zero(T), :nonstrict))
    )
end
@outer_constructor(ExponentiatedClass, (1,0))
@inline iscomposable(::ExponentiatedClass, κ::Kernel) = ismercer(κ)
@inline phi{T<:AbstractFloat}(ϕ::ExponentiatedClass{T}, z::T) = exp(ϕ.a*z + ϕ.c)


#== Other Mercer Classes ==#

doc"PolynomialClass(κ;a,c,d) = (a⋅κ + c)ᵈ"
immutable PolynomialClass{T<:AbstractFloat,U<:Integer} <: CompositionClass{T}
    a::Parameter{T}
    c::Parameter{T}
    d::Parameter{U}
    PolynomialClass(a::Variable{T}, c::Variable{T}, d::Variable{U}) = new(
        Parameter(a, LowerBound(zero(T), :strict)),
        Parameter(c, LowerBound(zero(T), :nonstrict)),
        Parameter(d, LowerBound(one(U),  :nonstrict))
    )
end
@outer_constructor(PolynomialClass, (1,0,3))
@inline iscomposable(::PolynomialClass, κ::Kernel) = ismercer(κ)
@inline phi{T<:AbstractFloat}(ϕ::PolynomialClass{T}, z::T) = (ϕ.a*z + ϕ.c)^ϕ.d


#== Non-Negative Negative Definite Kernel Classes ==#

abstract NonNegativeNegativeDefiniteClass{T<:AbstractFloat} <: CompositionClass{T}

doc"PowerClass(z;a,c,γ) = (az + c)ᵞ"
immutable PowerClass{T<:AbstractFloat} <: NonNegativeNegativeDefiniteClass{T}
    a::Parameter{T}
    c::Parameter{T}
    gamma::Parameter{T}
    PowerClass(a::Variable{T}, c::Variable{T}, γ::Variable{T}) = new(
        Parameter(a, LowerBound(zero(T), :strict)),
        Parameter(c, LowerBound(zero(T), :nonstrict)),
        Parameter(γ, Interval(Bound(zero(T), :strict), Bound(one(T), :nonstrict)))
    )
end
@outer_constructor(PowerClass, (1,0,0.5))
@inline iscomposable(::PowerClass, κ::Kernel) = isnegdef(κ) && isnonnegative(κ)
@inline phi{T<:AbstractFloat}(ϕ::PowerClass{T}, z::T) = (ϕ.a*z + ϕ.c)^(ϕ.gamma)


doc"GammmaLogClass(z;α,γ) = log(1 + α⋅zᵞ)"
immutable GammaLogClass{T<:AbstractFloat} <: NonNegativeNegativeDefiniteClass{T}
    alpha::Parameter{T}
    gamma::Parameter{T}
    GammaLogClass(α::Variable{T}, γ::Variable{T}) = new(
        Parameter(α, LowerBound(zero(T), :strict)),
        Parameter(γ, Interval(Bound(zero(T), :strict), Bound(one(T), :nonstrict)))
    )
end
@outer_constructor(GammaLogClass, (1,0.5))
@inline iscomposable(::GammaLogClass, κ::Kernel) = isnegdef(κ) && isnonnegative(κ)
@inline phi{T<:AbstractFloat}(ϕ::GammaLogClass{T}, z::T) = log(ϕ.alpha*z^(ϕ.gamma) + 1)


doc"LogClass(z;α) = log(1 + α⋅z)"
immutable LogClass{T<:AbstractFloat} <: NonNegativeNegativeDefiniteClass{T}
    alpha::Parameter{T}
    LogClass(α::Variable{T}) = new(
        Parameter(α, LowerBound(zero(T), :strict))
    )
end
@outer_constructor(LogClass, (1,))
@inline iscomposable(::LogClass, κ::Kernel) = isnegdef(κ) && isnonnegative(κ)
@inline phi{T<:AbstractFloat}(ϕ::LogClass{T}, z::T) = log(ϕ.alpha*z + 1)


#== Non-Mercer, Non-Negative Definite Classes ==#

doc"SigmoidClass(κ;α,c) = tanh(a⋅κ + c)"
immutable SigmoidClass{T<:AbstractFloat} <: CompositionClass{T}
    a::Parameter{T}
    c::Parameter{T}
    SigmoidClass(a::Variable{T}, c::Variable{T}) = new(
        Parameter(a, LowerBound(zero(T), :strict)),
        Parameter(c, LowerBound(zero(T), :nonstrict))   
    )
end
@outer_constructor(SigmoidClass, (1,0))
@inline iscomposable(::SigmoidClass, κ::Kernel) = ismercer(κ)
@inline phi{T<:AbstractFloat}(ϕ::SigmoidClass{T}, z::T) = tanh(ϕ.a*z + ϕ.c)


#== Properties of Kernel Classes ==#

for (classobj, properties) in (
        (PositiveMercerClass, (true, false, false, false, true)),
        (NonNegativeNegativeDefiniteClass, (false, true, false, true, true)),
        (PolynomialClass, (true, false, true, true, true)),
        (SigmoidClass, (false, false, true, true, true))
    )
    ismercer(::classobj) = properties[1]
    isnegdef(::classobj) = properties[2]
    attainsnegative(::classobj) = properties[3]
    attainszero(::classobj)     = properties[4]
    attainspositive(::classobj) = properties[5]
end




#==========================================================================
  Exponential Class
==========================================================================

doc"ExponentialClass(κ;α,γ) = exp(-α⋅κᵞ)"
immutable ExponentialClass{T<:AbstractFloat} <: PositiveMercerClass{T}
    alpha::Parameter{T}
    gamma::Parameter{T}
    ExponentialClass(α::Variable{T}, γ::Variable{T}) = new(
        Parameter(α, Interval(Bound(zero(T)))),
        Parameter(γ, Interval(Bound(zero(T)), Bound(one(T), false)))
    )
end
ExponentialClass{T<:AbstractFloat}(α::Variable{T}, γ::Variable{T}) = ExponentialClass{T}(α, γ)
function ExponentialClass(α::Variable=1, γ::Variable=1)
    ExponentialClass(promote_arguments(Float64, α, γ)...)
end

iscomposable(::ExponentialClass, κ::Kernel) = is_nonneg_and_negdef(κ)
checkcase{T<:AbstractFloat}(ϕ::ExponentialClass{T}) = ϕ.gamma == one(T) ? Val{:γ1} : Val

function description_string{T<:AbstractFloat}(ϕ::ExponentialClass{T}, eltype::Bool = true)
    "Exponential" * (eltype ? "{$(T)}" : "") * "(α=$(ϕ.alpha.value),γ=$(ϕ.gamma.value))"
end

@inline phi{T<:AbstractFloat}(ϕ::ExponentialClass{T},::Type{Val}, z::T) = exp(-ϕ.alpha * z^ϕ.gamma)
@inline phi{T<:AbstractFloat}(ϕ::ExponentialClass{T},::Type{Val{:γ1}}, z::T) = exp(-ϕ.alpha * z)


==========================================================================
  Rational Class
==========================================================================

doc"RationalClass(κ;α,β,γ) = (1 + α⋅κᵞ)⁻ᵝ"
immutable RationalClass{T<:AbstractFloat} <: PositiveMercerClass{T}
    alpha::Parameter{T}
    beta::Parameter{T}
    gamma::Parameter{T}
    RationalClass(α::Variable{T}, β::Variable{T}, γ::Variable{T}) = new(
        Parameter(α, Interval(Bound(zero(T)))),
        Parameter(β, Interval(Bound(zero(T)))),
        Parameter(γ, Interval(Bound(zero(T)), Bound(one(T), false)))
    )
end
function RationalClass{T<:AbstractFloat}(α::Variable{T}, β::Variable{T}, γ::Variable{T})
    RationalClass{T}(α, β, γ)
end
function RationalClass(α::Variable=1, β::Variable=1, γ::Variable{Real}=1)
    RationalClass(promote_arguments(Float64, α, β, γ)...)
end

iscomposable(::RationalClass, κ::Kernel) = is_nonneg_and_negdef(κ)
function checkcase{T<:AbstractFloat}(ϕ::RationalClass{T})
    if ϕ.gamma == one(T)
        ϕ.beta == one(T) ? Val{:γ1β1} : Val{:γ1}
    else
        ϕ.beta == one(T) ? Val{:β1} : Val
    end
end

function description_string{T<:AbstractFloat}(ϕ::RationalClass{T}, eltype::Bool = true)
    "Rational" * (eltype ? "{$(T)}" : "") * "(α=$(ϕ.alpha.value),β=$(ϕ.beta.value),γ=$(ϕ.gamma.value))"
end

@inline phi{T<:AbstractFloat}(ϕ::RationalClass{T},::Type{Val}, z::T) = (1 + ϕ.alpha * z^ϕ.gamma)^(-ϕ.beta)
@inline phi{T<:AbstractFloat}(ϕ::RationalClass{T},::Type{Val{:γ1}}, z::T) = (1 + ϕ.alpha)^(-ϕ.beta)
@inline phi{T<:AbstractFloat}(ϕ::RationalClass{T},::Type{Val{:β1}}, z::T) = 1/(1 + ϕ.alpha * z^ϕ.gamma)
@inline phi{T<:AbstractFloat}(ϕ::RationalClass{T},::Type{Val{:γ1β1}}, z::T) = 1/(1 + ϕ.alpha * z)


==========================================================================
  Matern Class
==========================================================================

doc"MatérnClass(κ;ν,ρ) = 2ᵛ⁻¹(√(2ν)κ/ρ)ᵛKᵥ(√(2ν)κ/ρ)/Γ(ν)"
immutable MaternClass{T<:AbstractFloat} <: PositiveMercerClass{T}
    nu::Parameter{T}
    rho::Parameter{T}
    MaternClass(ν::Variable{T}, ρ::Variable{T}) = new(
        Parameter(ν, Interval(Bound(zero(T)))),
        Parameter(ρ, Interval(Bound(zero(T))))
    )
end
MaternClass{T<:AbstractFloat}(ν::Variable{T}, ρ::Variable{T}) = MercerClass{T}(ν, ρ)
function MaternClass(ν::Variable=1, ρ::Variable=1)
    MaternClass(promote_arguments(Float64, ν, ρ)...)
end

iscomposable(::MaternClass, κ::Kernel) = is_nonneg_and_negdef(κ)

function description_string{T<:AbstractFloat}(ϕ::MaternClass{T}, eltype::Bool = true)
    "Matérn" * (eltype ? "{$(T)}" : "") * "(ν=$(ϕ.ν.value),ρ=$(ϕ.ρ.value))"
end

@inline function phi{T<:AbstractFloat}(ϕ::MaternClass{T}, ::Type{Val}, z::T)
    v1 = sqrt(2ϕ.nu) * z / ϕ.rho
    v1 = v1 < eps(T) ? eps(T) : v1  # Overflow risk, z -> Inf
    2 * (v1/2)^(ϕ.nu) * besselk(ϕ.nu, v1) / gamma(ϕ.nu)
end


==========================================================================
  Exponentiated Class
==========================================================================

doc"ExponentiatedClass(κ;α) = exp(a⋅κ + c)"
immutable ExponentiatedClass{T<:AbstractFloat} <: PositiveMercerClass{T}
    a::Parameter{T}
    c::Parameter{T}
    ExponentiatedClass(a::Variable{T}, c::Variable{T}) = new(
        Parameter(a, Interval(Bound(zero(T)))),
        Parameter(c, Interval(Bound(zero(T), false)))
    )
end
ExponentiatedClass{T<:Real}(a::Variable{T}, c::Variable{T}) = ExponentiatedClass{T}(a, c)
function ExponentiatedClass(a::Variable, c::Variable)
    ExponentiatedClass(promote_arguments(Float64, a, c)...)
end

function iscomposable(::ExponentiatedClass, κ::Kernel)
    ismercer(κ) || error("Composed kernel must be a Mercer class.")
end

function description_string{T<:AbstractFloat}(ϕ::ExponentiatedClass{T}, eltype::Bool = true)
    "Exponentiated" * (eltype ? "{$(T)}" : "") * "(a=$(ϕ.a.value),c=$(ϕ.c.value))"
end

@inline phi{T<:AbstractFloat}(ϕ::ExponentiatedClass{T}, ::Type{Val}, z::T) = exp(ϕ.a*z + ϕ.c)


==========================================================================
  Polynomial Class
==========================================================================

doc"PolynomialClass(κ;a,c,d) = (a⋅κ + c)ᵈ"
immutable PolynomialClass{T<:AbstractFloat,U<:Integer} <: CompositionClass{T}
    a::Parameter{T}
    c::Parameter{T}
    d::Parameter{U}
    PolynomialClass(a::Variable{T}, c::Variable{T}, d::Fixed{U}) = new(
        Parameter(a, Interval(Bound(zero(T)))),
        Parameter(c, Interval(Bound(zero(T), false))),
        Parameter(d, Interval(Bound(one(U))))
    )
end
function PolynomialClass{T<:AbstractFloat,U<:Integer}(a::Variable{T}, b::Variable{T}, d::Variable{U})
    PolynomialClass{T,U}(a, b, Fixed(d))
end
function PolynomialClass(a::Variable=1, b::Variable=1, d::Variable{Integer}=3)
    PolynomialClass(promote_arguments(Float64, a, b)..., d)
end

function iscomposable(::PolynomialClass, κ::Kernel)
    ismercer(κ) || error("Composed class must be a Mercer class.")
end

ismercer(::PolynomialClass) = true

function description_string{T<:AbstractFloat}(ϕ::PolynomialClass{T}, eltype::Bool = true) 
    "Polynomial" * (eltype ? "{$(T)}" : "") * "(a=$(ϕ.a.value),c=$(ϕ.c.value),d=$(ϕ.d.value))"
end

@inline phi{T<:AbstractFloat}(ϕ::PolynomialClass{T}, ::Type{Val}, z::T) = (ϕ.a*z + ϕ.c)^ϕ.d


==========================================================================
  Sigmoid Class
==========================================================================

doc"SigmoidClass(κ;α,c) = tanh(a⋅κ + c)"
immutable SigmoidClass{T<:AbstractFloat} <: CompositionClass{T}
    a::Parameter{T}
    c::Parameter{T}
    SigmoidClass(a::Variable{T}, c::Variable{T}) = new(
        Parameter(a, Interval(Bound(zero(T)))),
        Parameter(c, Interval(Bound(zero(T), false)))   
    )
end
SigmoidClass{T<:AbstractFloat}(a::Variable{T}, c::Variable{T}) = SigmoidClass{T}(a,c)
SigmoidClass(a::Variable=1, c::Variable=1) = SigmoidClass(promote_arguments(Float64, a, c)...)

function iscomposable(::SigmoidClass, κ::Kernel)
    ismercer(κ) || error("Composed class must be a Mercer class.")
end

function description_string{T<:AbstractFloat}(ϕ::SigmoidClass{T}, eltype::Bool = true)
    "Sigmoid" * (eltype ? "{$(T)}" : "") * "(a=$(ϕ.a.value),c=$(ϕ.c.value))"
end

@inline phi{T<:AbstractFloat}(ϕ::SigmoidClass{T}, ::Type{Val}, z::T) = tanh(ϕ.a*z + ϕ.c)


==========================================================================
  Power Class
==========================================================================

doc"PowerClass(z;γ) = (az + c)ᵞ"
immutable PowerClass{T<:AbstractFloat} <: NonNegativeNegativeDefiniteClass{T}
    a::Parameter{T}
    c::Parameter{T}
    gamma::Parameter{T}
    PowerClass(a::Variable{T}, c::Variable{T}, γ::Variable{T}) = new(
        Parameter(a, Interval(Bound(zero(T)))),
        Parameter(c, Interval(Bound(zero(T), false))),
        Parameter(γ, Interval(Bound(zero(T)), Bound(one(T), false)))
    )
end
function PowerClass{T<:AbstractFloat}(a::Variable{T}, c::Variable{T}, γ::Variable{T})
    PowerClass{T}(a, c, γ)
end
function PowerClass(a::Variable=1, c::Variable=0, γ::Variable=1) 
    PowerClass(promote_arguments(Float64, a, c, γ)...)
end

iscomposable(::PowerClass, κ::Kernel) = is_nonneg_and_negdef(κ)
checkcase{T<:AbstractFloat}(ϕ::PowerClass{T}) = ϕ.gamma == one(T) ? Val{:γ1} : Val


function description_string{T<:AbstractFloat}(ϕ::PowerClass{T}, eltype::Bool = true)
    "Power" * (eltype ? "{$(T)}" : "") * "(a=$(ϕ.a.value),c=$(ϕ.c.value),γ=$(ϕ.gamma.value))"
end

@inline phi{T<:AbstractFloat}(ϕ::PowerClass{T}, ::Type{Val}, z::T) = (ϕ.a*z + ϕ.c)^(ϕ.gamma)
@inline phi{T<:AbstractFloat}(ϕ::PowerClass{T}, ::Type{Val{:γ1}}, z::T) = ϕ.a*z + ϕ.c


==========================================================================
  Log Class
==========================================================================

doc"LogClass(z;α,γ) = log(1 + α⋅zᵞ)"
immutable LogClass{T<:AbstractFloat} <: NonNegativeNegativeDefiniteClass{T}
    alpha::Parameter{T}
    gamma::Parameter{T}
    LogClass(α::Variable{T}, γ::Variable{T}) = new(
        Parameter(α, Interval(Bound(zero(T)))),
        Parameter(γ, Interval(Bound(zero(T)), Bound(one(T))))
    )
end
LogClass{T<:Real}(α::Variable{T}, γ::Variable{T}) = LogClass{T}(α, γ)
LogClass(α::Variable=1, γ::Variable=1) = LogClass(promote_arguments(Float64, α, γ)...)

iscomposable(::LogClass, κ::Kernel) = is_nonneg_and_negdef(κ)
checkcase{T<:AbstractFloat}(ϕ::LogClass{T}) = ϕ.gamma == one(T) ? Val{:γ1} : Val

function description_string{T<:AbstractFloat}(ϕ::LogClass{T}, eltype::Bool = true)
    "Log" * (eltype ? "{$(T)}" : "") * "(α=$(ϕ.alpha.value),γ=$(ϕ.gamma.value))"
end

@inline phi{T<:AbstractFloat}(ϕ::LogClass{T}, z::T) = log(ϕ.alpha*z^(ϕ.gamma) + 1)
@inline phi{T<:AbstractFloat}(ϕ::LogClass{T}, ::Type{Val{:γ1}}, z::T) = log(ϕ.alpha*z + 1)

=#
