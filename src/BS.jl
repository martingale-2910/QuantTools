module BS

export compute_value, compute_delta, compute_vega, compute_theta, compute_rho, compute_gamma, compute_vanna, compute_volga, compute_implied_vol, d1, d2, df

using Distributions: Normal, cdf, pdf
using Logging

N01 = Normal()

Φ(x) = cdf(N01, x)
φ(x) = pdf(N01, x)

"""
    d1(S::Float64, q::Float64, r::Float64, vol::Float64, K::Float64, T::Float64)

Compute the `d₁` score used to determine the risk-adjusted probability that the option will be in-the-money.

# Examples
```julia-repl
julia> d1(100., 0., 0.05, 0.2, 110, 1.)
-0.12655089902162442
```
"""
function d1(S::Float64, q::Float64, r::Float64, vol::Float64, K::Float64, T::Float64)
    return (log(S/K) + ((r - q) + 0.5*vol^2)*T)/(vol*sqrt(T))
end

"""
    d2(S::Float64, q::Float64, r::Float64, vol::Float64, K::Float64, T::Float64)

Compute the `d₂` score used to determine the probability that the option will `not` be in-the-money.

# Examples
```julia-repl
julia> d2(100., 0., 0.05, 0.2, 110, 1.)
-0.32655089902162443
```
"""
function d2(S::Float64, q::Float64, r::Float64, vol::Float64, K::Float64, T::Float64)
    return (log(S/K) + ((r - q) - 0.5*vol^2)*T)/(vol*sqrt(T))
end

"""
    df(r::Float64, t::Float64)

Compute the time `t` discount factor in the Black-Scholes model with interest rate `r`.

# Examples
```julia-repl
julia> df(0.05, 1.)
0.951229424500714
```
"""
function df(r::Float64, t::Float64)
    return exp(-r*t)
end

"""
    compute_value(S::Float64, q::Float64, r::Float64, vol::Float64, K::Float64, T::Float64, is_call::Bool)

Compute the Black-Scholes fair value `V` of a European option with Strike `K` expiring in `T` years on an underlying with dividend rate `q`, spot value `S` and volatility `vol` given the interest rate `r`.

The argument `is_call` specifies whether the contract is a Call or a Put.

# Examples
```julia-repl
julia> compute_value(100., 0., 0.05, 0.2, 110., 1., true)
6.040088129724232
```
"""
function compute_value(S::Float64, q::Float64, r::Float64, vol::Float64, K::Float64, T::Float64, is_call::Bool)
    if is_call
        return S*df(q, T)*Φ(d1(S, q, r, vol, K, T)) - K*df(r, T)*Φ(d2(S, q, r, vol, K, T))
    else
        return K*df(r, T)*Φ(-d2(S, q, r, vol, K, T)) - S*df(q, T)*Φ(-d1(S, q, r, vol, K, T))
    end
end

"""
    compute_delta(S::Float64, q::Float64, r::Float64, vol::Float64, K::Float64, T::Float64, is_call::Bool)

Compute the Black-Scholes delta `Δ` (`∂V/∂S`) of a European option with Strike `K` expiring in `T` years on an underlying with dividend rate `q`, spot value `S` and volatility `vol` given the interest rate `r`.

The argument `is_call` specifies whether the contract is a Call or a Put.

# Examples
```julia-repl
julia> compute_delta(100., 0., 0.05, 0.2, 110., 1., true)
0.44964793063717595
```
"""
function compute_delta(S::Float64, q::Float64, r::Float64, vol::Float64, K::Float64, T::Float64, is_call::Bool)
    if is_call
        return df(q, T)*Φ(d1(S, q, r, vol, K, T))
    else
        return -df(q, T)*Φ(-d1(S, q, r, vol, K, T))
    end
end

"""
    compute_vega(S::Float64, q::Float64, r::Float64, vol::Float64, K::Float64, T::Float64, is_call::Bool)

Compute the Black-Scholes vega `ν` (`∂V/∂σ`) of a European option with Strike `K` expiring in `T` years on an underlying with dividend rate `q`, spot value `S` and volatility `vol` given the interest rate `r`.

The argument `is_call` specifies whether the contract is a Call or a Put.

# Examples
```julia-repl
julia> compute_vega(100., 0., 0.05, 0.2, 110., 1., true)
39.57604803881934
```
"""
function compute_vega(S::Float64, q::Float64, r::Float64, vol::Float64, K::Float64, T::Float64, is_call::Bool)
    if is_call  # Both expressions are actually equal
        return S*df(q, T)*sqrt(T)*φ(d1(S, q, r, vol, K, T))
    else
        return K*df(r, T)*sqrt(T)*φ(d2(S, q, r, vol, K, T))
    end
end

"""
    compute_theta(S::Float64, q::Float64, r::Float64, vol::Float64, K::Float64, T::Float64, is_call::Bool)

Compute the Black-Scholes theta `θ` (`∂V/∂T`) of a European option with Strike `K` expiring in `T` years on an underlying with dividend rate `q`, spot value `S` and volatility `vol` given the interest rate `r`.

The argument `is_call` specifies whether the contract is a Call or a Put.

# Examples
```julia-repl
julia> compute_theta(100., 0., 0.05, 0.2, 110., 1., true)
-5.903840050581602
```
"""
function compute_theta(S::Float64, q::Float64, r::Float64, vol::Float64, K::Float64, T::Float64, is_call::Bool)
    if is_call
        return -df(q, T)*S*φ(d1(S, q, r, vol, K, T))*vol/(2*sqrt(T)) - r*K*df(r, T)*Φ(d2(S, q, r, vol, K, T)) + q*S*df(q, T)*Φ(d1(S, q, r, vol, K, T))
    else
        return -df(q, T)*S*φ(d1(S, q, r, vol, K, T))*vol/(2*sqrt(T)) + r*K*df(r, T)*Φ(d2(S, q, r, vol, K, T)) - q*S*df(q, T)*Φ(d1(S, q, r, vol, K, T))
    end
end

"""
    compute_rho(S::Float64, q::Float64, r::Float64, vol::Float64, K::Float64, T::Float64, is_call::Bool)

Compute the Black-Scholes rho `ρ` (`∂V/∂r`) of a European option with Strike `K` expiring in `T` years on an underlying with dividend rate `q`, spot value `S` and volatility `vol` given the interest rate `r`.

The argument `is_call` specifies whether the contract is a Call or a Put.

# Examples
```julia-repl
julia> compute_rho(100., 0., 0.05, 0.2, 110., 1., true)
38.92470493399336
```
"""
function compute_rho(S::Float64, q::Float64, r::Float64, vol::Float64, K::Float64, T::Float64, is_call::Bool)
    if is_call
        return K*T*df(r, T)*Φ(d2(S, q, r, vol, K, T))
    else
        return -K*T*df(r, T)*Φ(-d2(S, q, r, vol, K, T))
    end
end

"""
    compute_gamma(S::Float64, q::Float64, r::Float64, vol::Float64, K::Float64, T::Float64, is_call::Bool)

Compute the Black-Scholes gamma `Γ` (`∂²V/∂S²`) of a European option with Strike `K` expiring in `T` years on an underlying with dividend rate `q`, spot value `S` and volatility `vol` given the interest rate `r`.

The argument `is_call` specifies whether the contract is a Call or a Put.

# Examples
```julia-repl
julia> compute_gamma(100., 0., 0.05, 0.2, 110., 1., true)
0.019788024019409666
```
"""
function compute_gamma(S::Float64, q::Float64, r::Float64, vol::Float64, K::Float64, T::Float64, is_call::Bool)
    if is_call  # Both expressions are actually equal
        return df(q, T)*φ(d1(S, q, r, vol, K, T))/(S*vol*sqrt(T))
    else
        return df(r, T)*K*φ(d2(S, q, r, vol, K, T))/(S^2*vol*sqrt(T))
    end
end

"""
    compute_vanna(S::Float64, q::Float64, r::Float64, vol::Float64, K::Float64, T::Float64, is_call::Bool)

Compute the Black-Scholes vanna (`∂²V/∂S∂σ`) of a European option with Strike `K` expiring in `T` years on an underlying with dividend rate `q`, spot value `S` and volatility `vol` given the interest rate `r`.

The argument `is_call` specifies whether the contract is a Call or a Put.

# Examples
```julia-repl
julia> compute_vanna(100., 0., 0.05, 0.2, 110., 1., true)
0.6461797033399724
```
"""
function compute_vanna(S::Float64, q::Float64, r::Float64, vol::Float64, K::Float64, T::Float64, is_call::Bool)
    return -df(q, T)*φ(d1(S, q, r, vol, K, T))*d2(S, q, r, vol, K, T)/vol
end

"""
    compute_volga(S::Float64, q::Float64, r::Float64, vol::Float64, K::Float64, T::Float64, is_call::Bool)

Compute the Black-Scholes volga (`∂²V/∂σ²`) of a European option with Strike `K` expiring in `T` years on an underlying with dividend rate `q`, spot value `S` and volatility `vol` given the interest rate `r`.

The argument `is_call` specifies whether the contract is a Call or a Put.

# Examples
```julia-repl
julia> compute_volga(100., 0., 0.05, 0.2, 110., 1., true)
8.17746223872001
```
"""
function compute_volga(S::Float64, q::Float64, r::Float64, vol::Float64, K::Float64, T::Float64, is_call::Bool)
    return df(q, T)*S*sqrt(T)*φ(d1(S, q, r, vol, K, T))*d1(S, q, r, vol, K, T)*d2(S, q, r, vol, K, T)/vol
end

"""
    compute_implied_vol(S::Float64, q::Float64, r::Float64, V::Float64, K::Float64, T::Float64, is_call::Bool; max_iter::Int64=100, tol::Float64=1e-5)

Compute the Black-Scholes implied volatility of a European option with strike `K`, expiring in `T` years and quoted at price `V` on an underlying with dividend rate `q`, spot value `S` and volatility `vol` given the interest rate `r`.

The argument `is_call` specifies whether the contract is a Call or a Put.

Uses the bisection method to solve the equation `V = compute_value(S, q, r, σ, K, T, is_call)` for `σ` .

Computes at most `max_iter` (200 by default) iterations with a tolerance of `tol` (1e-2 by default) for the option value and `eps` (1e-8 by default) for the volatility.

# Examples
```julia-repl
julia> compute_implied_vol(100., 0., 0.05, 6.040088129724232, 110., 1., true)
0.19999999999999993
```
"""
function compute_implied_vol(S::Float64, q::Float64, r::Float64, V::Float64, K::Float64, T::Float64, is_call::Bool; max_iter::Int64=200, tol::Float64=1e-2, eps::Float64=1e-8, verbose::Bool=true)
    if (is_call && V < max(S - K*df(r, T), 0.0) || S < V) || (!is_call && V < max(K*df(r, T) - S, 0.0) || K*df(r, T) < V)
        if verbose
            @warn "Option arbitrage boundaries violated."
        end
        return NaN64
    end

    vol_low = 0.0
    vol_high = 10.0
    vol_mid = 0.5*(vol_high + vol_low)

    V_mid = compute_value(S, q, r, vol_mid, K, T, is_call)

    for _ in 0:max_iter
        if V_mid < V
            vol_low = vol_mid
        else
            vol_high = vol_mid
        end

        if abs(V_mid - V) < tol || abs(vol_high - vol_low) < eps
            return vol_mid
        else
            vol_mid = 0.5*(vol_high + vol_low)
            V_mid = compute_value(S, q, r, vol_mid, K, T, is_call)
        end
    end

    if abs(V_mid - V) >= tol && abs(vol_high - vol_low) >= eps
        if verbose
            @warn "Implied volatility did not converge." "abs(V_mid - V) = abs($V_mid - $V) = $(abs(V_mid - V))" "abs(vol_high - vol_low) = abs($vol_high - $vol_low) = $(abs(vol_high - vol_low))"
        end
        return NaN64
    else
        return vol_mid
    end
end

end # module BS