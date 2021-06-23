using POMDPs
using BeliefUpdaters
using POMDPSimulators
using POMDPModels
using POMCPOW
using ProgressMeter
using Plots
using Statistics
using PFTDPW
baby = BabyPOMDP()

t = 0.1
d=20
pft_solver = PFTDPWSolver(
    max_time=t,
    tree_queries=100_000,
    k_o = 5,
    k_a = 2,
    max_depth = d,
    c = 100.0,
    n_particles = 100,
    enable_action_pw = false,
    check_repeat_obs = true
)
pft_planner = solve(pft_solver, baby)

pomcpow_solver = POMCPOWSolver(
    max_time=t,
    tree_queries = 1_000_000,
    max_depth=d,
    criterion = MaxUCB(100.0),
    tree_in_info=true,
    enable_action_pw=false
)
pomcpow_planner = solve(pomcpow_solver, baby)

function benchmark(pomdp::POMDP, planner1::Policy, planner2::Policy; depth::Int=20, N::Int=100)
    r1Hist = Float64[]
    r2Hist = Float64[]
    ro = RolloutSimulator(max_steps=depth)
    upd = DiscreteUpdater(pomdp)
    @showprogress for i = 1:N
        r1 = simulate(ro, pomdp, planner1, upd)
        r2 = simulate(ro, pomdp, planner2, upd)
        push!(r1Hist, r1)
        push!(r2Hist, r2)
    end
    return (r1Hist, r2Hist)::Tuple{Vector{Float64},Vector{Float64}}
end

N = 100
r_pft, r_pomcp = benchmark(baby, pft_planner, pomcpow_planner, N=N)

histogram([r_pft r_pomcp], alpha=0.5, labels=["PFT-DPW" "POMCPOW"], normalize=true, legend=:topleft)
title!("Baby Benchmark\nt=$(t)s, d=$d, N=$N")
xlabel!("Returns")
ylabel!("Density")
mean(r_pft)
mean(r_pomcp)
std(r_pft)/sqrt(N)
std(r_pomcp)/sqrt(N)
