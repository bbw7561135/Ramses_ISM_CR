module pm_parameters
  use amr_parameters, ONLY: dp
  integer::nsinkmax=20000           ! Maximum number of sinks
  integer::npartmax=0               ! Maximum number of particles
  integer::npart=0                  ! Actual number of particles
  integer::nsink=0                  ! Actual number of sinks
  integer::iseed=0                  ! Seed for stochastic star formation
  integer::nstar_tot=0              ! Total number of star particle
  real(dp)::mstar_tot=0             ! Total star mass
  real(dp)::mstar_lost=0            ! Missing star mass


  ! More sink related parameters, can all be set in namelist file

  integer::ir_cloud=4                        ! Radius of cloud region in unit of grid spacing (i.e. the ACCRETION RADIUS)
  integer::ir_cloud_massive=3                ! Radius of massive cloud region in unit of grid spacing for PM sinks
  real(dp)::sink_soft=2.d0                   ! Sink grav softening length in dx at levelmax for "direct force" sinks
  real(dp)::msink_direct=-1.d0               ! mass above which sinks are treated as "direct force" objectfs
  
  logical::create_sinks=.false.              ! turn formation of new sinks on

  character(LEN=15)::merging_scheme='none'   ! sink merging scheme. options: 'none,'timescale', 'FOF'
  real(dp)::merging_timescale=-1.d0          ! time during which sinks are considered for merging (only when 'timescale' is used), 
                                             ! used also as contraction timescale in creation
  real(dp)::cont_speed=0.

  character(LEN=15)::accretion_scheme='none' ! sink accretion scheme. options: 'none', 'flux', 'bondi', 'threshold'
  logical::flux_accretion=.false.
  logical::threshold_accretion=.false.
  logical::bondi_accretion=.false.

  logical::nol_accretion=.false.             ! Leave angular momentum in the gas at accretion
  real(dp)::sink_seedmass=0.0                ! Initial sink mass. If < 0, use the AGN feedback based recipe
  real(dp)::c_acc=-1.0                       ! "courant factor" for sink accretion time step control.
                                             ! gives fration of available gas that can be accreted in one timestep.

  logical::eddington_limit=.false.           ! Switch for Eddington limit for the smbh case
  logical::sink_drag=.false.                 ! Gas dragging sink
  logical::clump_core=.false.                ! Trims the clump (for star formation)
  logical::smbh_verbose=.false.              ! Controls print verbosity for the SMBH case
  real(dp)::alpha_acc_boost=1.0              ! Boost coefficient for accretion
  real(dp)::alpha_drag_boost=1.0             ! Boost coefficient for drag
  real(dp)::acc_threshold_creation = 1.e20   ! Threshold for sink creation in smbh case; in Msun/yr
  real(dp)::mass_vel_check = -1.0            ! Threshold for velocity check in  merging, in unit of mass_sph; by default don't check
  real(dp)::T2_AGN = 0.15*1d12               ! AGN temperature in Kelvin
  real(dp)::T2_min = 1d7                     ! Minimum AGN blast temperature in Kelvin

end module pm_parameters
