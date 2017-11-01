module amr_parameters

  ! Define real types
  integer,parameter::sp=kind(1.0E0)
#ifndef NPRE
  integer,parameter::dp=kind(1.0E0) ! default
#else
#if NPRE==4
  integer,parameter::dp=kind(1.0E0) ! real*4
#else
  integer,parameter::dp=kind(1.0D0) ! real*8
#endif
#endif
#ifdef QUADHILBERT
  integer,parameter::qdp=kind(1.0_16) ! real*16
#else
  integer,parameter::qdp=kind(1.0_8) ! real*8
#endif
  integer,parameter::MAXOUT=1000
  integer,parameter::MAXLEVEL=100
  
  ! Define integer types (for particle IDs mostly)
  integer,parameter::i4b=4
#ifndef LONGINT
  integer,parameter::i8b=4  ! default long int are short int
#else
  integer,parameter::i8b=8  ! long int are long int
#endif

  ! Number of dimensions
#ifndef NDIM
  integer,parameter::ndim=1
#else
  integer,parameter::ndim=NDIM
#endif
  integer,parameter::twotondim=2**ndim
  integer,parameter::threetondim=3**ndim
  integer,parameter::twondim=2*ndim

  ! Vectorization parameter
#ifndef NVECTOR
  integer,parameter::nvector=500  ! Size of vector sweeps
#else
  integer,parameter::nvector=NVECTOR
#endif

  integer, parameter :: nstride = 65536

  ! Run control
  logical::verbose =.false.   ! Write everything
  logical::verbosed=.false.   ! Write everything for dust diffusion
  logical::hydro   =.false.   ! Hydro activated
  logical::pic     =.false.   ! Particle In Cell activated
  logical::poisson =.false.   ! Poisson solver activated
  logical::cosmo   =.false.   ! Cosmology activated
  logical::star    =.false.   ! Star formation activated
  logical::sink    =.false.   ! Sink particles activated
  logical::rt      =.false.   ! Radiative transfer activated
  logical::debug   =.false.   ! Debug mode activated
  logical::static  =.false.   ! Static mode activated
  logical::static_dm=.false.  ! Static mode for dm only activated
  logical::static_gas=.false. ! Static mode for gas only activated
  logical::dust_barr=.false.  ! Activate to have barrenblatt equation
  logical::dust_lin=.false.   ! Activate to have linear dust equation
  logical::static_stars=.false.! Static mode for stars only activated
  logical::tracer  =.false.   ! Tracer particles activated
  logical::lightcone=.false.  ! Enable lightcone generation
  logical::clumpfind=.false.  ! Enable clump finder
  logical::aton=.false.       ! Enable ATON coarse grid radiation transfer
  logical::FLD     =.false.   ! FLD module activated
  logical::DTU     =.false.   ! Unique time-step activated for niMHD diffusion routines
  logical :: radiative_nimhdheating=.false. ! Enable niMHD heating as a source term in radiative transfer
  logical::dust_diffusion=.false. ! Enable dust diffusion (Price and Laibe 2015)

  ! Mesh parameters
  integer::geom=1             ! 1: cartesian, 2: cylindrical, 3: spherical
  integer::nx=1,ny=1,nz=1     ! Number of coarse cells in each dimension
  integer::levelmin=1         ! Full refinement up to levelmin
  integer::nlevelmax=1        ! Maximum number of level
  integer::ngridmax=0         ! Maximum number of grids
  integer,dimension(1:MAXLEVEL)::nexpand=1 ! Number of mesh expansion
  integer::nexpand_bound=1    ! Number of mesh expansion for virtual boundaries
  real(dp)::boxlen=1.0D0      ! Box length along x direction
  character(len=128)::ordering='hilbert'
  logical::cost_weighting=.true. ! Activate load balancing according to cpu time
  ! Recursive bisection tree parameters
  integer::nbilevelmax=1      ! Max steps of bisection partitioning
  integer::nbinodes=3         ! Max number of internal nodes
  integer::nbileafnodes=2     ! Max number of leaf (terminal) nodes
  real(dp)::bisec_tol=0.05d0  ! Tolerance for bisection load balancing

  ! Step parameters
  integer::nrestart=0         ! New run or backup file number
  integer::nrestart_quad=0    ! Restart with double precision Hilbert keys
  real(dp)::trestart=0.0      ! Restart time
  logical::restart_remap=.false. ! Force load balance on restart
  integer::nstepmax=1000000   ! Maximum number of time steps
  integer::ncontrol=1         ! Write control variables
  integer::fbackup=1000000    ! Backup data to disk
  integer::nremap=0           ! Load balancing frequency (0: never)

  ! Output parameters
  integer::iout=1             ! Increment for output times
  integer::ifout=1            ! Increment for output files
  integer::iback=1            ! Increment for backup files
  integer::noutput=1          ! Total number of outputs
  integer::foutput=1000000    ! Frequency of outputs
  integer::output_mode=0      ! Output mode (for hires runs)
  logical::gadget_output=.false. ! Output in gadget format
  logical::output_now=.false. ! write output next step
  logical::writing=.false.    ! Write column density and save files
  logical::write_conservative=.false. ! if .true., uold is dumped in outputs

  ! Column density module (Valdivia & Hennebelle 2014)
  integer::NdirExt_m=10       ! Theta directions for screening
  integer::NdirExt_n=10       ! Phi directions for screening


  ! Lightcone parameters
  real(dp)::thetay_cone=12.5
  real(dp)::thetaz_cone=12.5
  real(dp)::zmax_cone=2.0

  ! Cosmology and physical parameters
  real(dp)::boxlen_ini        ! Box size in h-1 Mpc
  real(dp)::omega_b=0.045     ! Omega Baryon
  real(dp)::omega_m=1.0D0     ! Omega Matter
  real(dp)::omega_l=0.0D0     ! Omega Lambda
  real(dp)::omega_k=0.0D0     ! Omega Curvature
  real(dp)::h0     =1.0D0     ! Hubble constant in km/s/Mpc
  real(dp)::aexp   =1.0D0     ! Current expansion factor
  real(dp)::hexp   =0.0D0     ! Current Hubble parameter
  real(dp)::texp   =0.0D0     ! Current proper time
  real(dp)::n_sink = -1.d0    ! Sink particle density threshold in H/cc
  real(dp)::rho_sink = -1.D0  ! Sink particle density threshold in g/cc
  real(dp)::d_sink = -1.D0    ! Sink particle density threshold in user units
  real(dp)::m_star =-1.0      ! Star particle mass in units of mass_sph
  real(dp)::n_star =0.1D0     ! Star formation density threshold in H/cc
  real(dp)::t_star =0.0D0     ! Star formation time scale in Gyr
  real(dp)::eps_star=0.0D0    ! Star formation efficiency (0.02 at n_star=0.1 gives t_star=8 Gyr)
  real(dp)::T2_star=10.0D0    ! Typical ISM polytropic temperature
  real(dp)::g_star =1.6D0     ! Typical ISM polytropic index
  real(dp)::jeans_ncells=-1   ! Jeans polytropic EOS
  real(dp)::del_star=2.D2     ! Minimum overdensity to define ISM
  real(dp)::eta_sn =0.0D0     ! Supernova mass fraction
  real(dp)::eta_ssn=0.95      ! Single supernova ejected mass fraction (sf_imf=.true. only)
  real(dp)::yield  =0.0D0     ! Supernova yield
  real(dp)::f_ek   =1.0D0     ! Supernovae kinetic energy fraction (only between 0 and 1)
  real(dp)::rbubble=0.0D0     ! Supernovae superbubble radius in pc
  real(dp)::f_w    =0.0D0     ! Supernovae mass loading factor
  integer ::ndebris=1         ! Supernovae debris particle number
  real(dp)::mass_gmc=-1.0     ! Stochastic exploding GMC mass
  real(dp)::z_ave  =0.0D0     ! Average metal abundance
  real(dp)::B_ave  =0.0D0     ! Average magnetic field
  real(dp)::z_reion=8.5D0     ! Reionization redshift
  real(dp)::T2_start          ! Starting gas temperature
  real(dp)::T2max= 1d50       ! Temperature ceiling for cooling_fine
  real(dp)::t_delay=1.0D1     ! Feedback time delay in Myr
  real(dp)::t_diss =20.0D0    ! Dissipation timescale for feedback
  real(dp)::t_sne =10.0D0     ! Supernova blast time
  real(dp)::J21    =0.0D0     ! UV flux at threshold in 10^21 units
  real(dp)::a_spec =1.0D0     ! Slope of the UV spectrum
  real(dp)::beta_fix=0.0D0    ! Pressure fix parameter
  real(dp)::kappa_IR=0d0      ! IR dust opacity
  real(dp)::ind_rsink=4.0d0   ! Number of cells defining the radius of the sphere where AGN feedback is active
  real(dp)::ir_eff=0.75       ! efficiency of the IR feedback (only when ir_feedback=.true.)
  real(dp)::sf_trelax=0.0D0   ! Relaxation time for star formation (cosmo=.false. only)
  real(dp)::sf_tdiss=0.0D0    ! Dissipation timescale for subgrid turbulence in units of turbulent crossing time
  integer::sf_model=3         ! Virial star formation model
  integer::nlevel_collapse=3  ! Number of levels to follow initial dark matter collapse (cosmo=.true. only)
  real(dp)::mass_star_max=120.0D0 ! Maximum mass of a star in solar mass
  real(dp)::mass_sne_min=10.0D0   ! Minimum mass of a single supernova in solar mass
  real(dp)::larson_lifetime=5000! lifetime of first larson core in years
  logical ::iso_jeans=.false. ! activate isothermal sound speed Jeans length refinement criterion
  real(dp)::Tp_jeans = 10.0d0 ! Default temperature to activate iso_jeans

  logical ::self_shielding=.false.
  logical ::pressure_fix=.false.
  logical ::nordlund_fix=.true.
  logical ::cooling=.false.
  logical ::neq_chem=.false.  ! Non-equilbrium chemistry activated
  logical ::isothermal=.false.
  logical ::metal=.false.
  logical ::haardt_madau=.false.
  logical ::delayed_cooling=.false.
  logical ::smbh=.false.
  logical ::agn=.false.
  logical ::use_proper_time=.false.
  logical ::convert_birth_times=.false. ! Convert stellar birthtimes: conformal -> proper
  logical ::ir_feedback=.false. ! Activate ir feedback from accreting sinks
  logical ::sf_virial=.false.   ! Activate SF Virial criterion
  logical ::sf_log_properties=.false. ! Log in ascii files birth properties of stars and supernovae
  logical ::sf_imf=.false.      ! Activate IMF sampling for SN feedback when resolution allows it
  logical ::sf_compressive=.false. ! Advect compressive and solenoidal turbulence terms separately
  logical ::sf_birth_properties=.false. ! Output birth properties of stars
  logical ::eos =.false.        ! non ideal gas EOS module activated
  logical ::barotrop=.false.    ! barotropic EOS for SF calculations
  logical ::racc_refine=.true.  ! Refine the grid around sink to the maximum level of refinement      
  logical ::clump_jeans=.false. ! Clump finder on cells violating Jeans criterion only
  logical ::dt_control=.false.  ! Impose a time step using dtdiff_params
  logical ::energy_fix=.false.  ! Use internal energy instead of total energy
  logical ::radiative=.true.    ! Radiative transfer
  logical ::extinction=.false.
  logical ::simplechem=.false.  ! H2 formation only
  real(dp)::p_UV   =1.0D0       ! Parameter of variation of G0 (UV) 

!Cosmic rays related variables
  logical ::cr_diffusion=.false.      ! Cosmic ray diffusion module activated
  logical ::fix_temp_diff=.false.     ! Cosmic ray diffusion energy fix
  logical ::alfven_diff_coeff=.false. ! CR diffusion coeffcient dependant on the Alfvenic Mach number
  logical ::slopelim_cond=.false.     ! TODO for the asymetric scheme
  logical ::isotrope_cond=.false.     ! Activate isotropic CR diffusion
  real(dp)::epsilon_diff_cr=1d-6      ! CG iteration break criteria for CR diffusion 
  integer :: niter_cr=0               ! Total number of iterations for CR diffusion
  
#ifdef grackle
  integer::grackle_comoving_coordinates=0
  integer::use_grackle=1
  integer::grackle_with_radiative_cooling=1
  integer::grackle_primordial_chemistry=0
  integer::grackle_metal_cooling=1
  integer::grackle_h2_on_dust=0
  integer::grackle_cmb_temperature_floor=1 
  integer::grackle_UVbackground=1
  logical::grackle_UVbackground_on=.false.
  character(len=256)::grackle_data_file
#endif

  ! Output times
  real(dp),dimension(1:MAXOUT)::aout=1.1       ! Output expansion factors
  real(dp),dimension(1:MAXOUT)::tout=0.0       ! Output times

  ! Movie
  integer::imovout=0             ! Increment for output times
  integer::imov=1                ! Initialize
  real(kind=8)::tstartmov=0.,astartmov=0.
  real(kind=8)::tendmov=0.,aendmov=0.
  real(kind=8),allocatable,dimension(:)::amovout,tmovout
  logical::movie=.false.
  integer::nw_frame=512 ! prev: nx_frame, width of frame in pixels
  integer::nh_frame=512 ! prev: ny_frame, height of frame in pixels
  integer::levelmax_frame=0
  real(kind=8),dimension(1:20)::xcentre_frame=0d0
  real(kind=8),dimension(1:20)::ycentre_frame=0d0
  real(kind=8),dimension(1:20)::zcentre_frame=0d0
  real(kind=8),dimension(1:10)::deltax_frame=0d0
  real(kind=8),dimension(1:10)::deltay_frame=0d0
  real(kind=8),dimension(1:10)::deltaz_frame=0d0
  real(kind=8),dimension(1:5)::dtheta_camera=0d0
  real(kind=8),dimension(1:5)::dphi_camera=0d0
  real(kind=8),dimension(1:5)::theta_camera=0d0
  real(kind=8),dimension(1:5)::phi_camera=0d0
  real(kind=8),dimension(1:5)::tstart_theta_camera=0d0
  real(kind=8),dimension(1:5)::tstart_phi_camera=0d0
  real(kind=8),dimension(1:5)::tend_theta_camera=0d0
  real(kind=8),dimension(1:5)::tend_phi_camera=0d0
  real(kind=8),dimension(1:5)::focal_camera=0d0
  real(kind=8),dimension(1:5)::dist_camera=0d0
  real(kind=8),dimension(1:5)::ddist_camera=0d0
  real(kind=8),dimension(1:5)::smooth_frame=1d0
  real(kind=8),dimension(1:5)::varmin_frame=0d0
  real(kind=8),dimension(1:5)::varmax_frame=1d60
  integer,dimension(1:5)::ivar_frame=0
  logical,dimension(1:5)::perspective_camera=.false.
  logical,dimension(1:5)::zoom_only_frame=.false.
  character(LEN=5)::proj_axis='z' ! x->x, y->y, projection along z
  character(LEN=6),dimension(1:5)::shader_frame='square'
  character(LEN=10),dimension(1:5)::method_frame='mean_mass'
#ifdef SOLVERmhd
  integer,dimension(0:NVAR+6)::movie_vars=0
  character(len=5),dimension(0:NVAR+6)::movie_vars_txt=''
#else
  integer,dimension(0:NVAR+2)::movie_vars=0
  character(len=5),dimension(0:NVAR+2)::movie_vars_txt=''
#endif

  ! Refinement parameters for each level
  real(dp),dimension(1:MAXLEVEL)::m_refine =-1.0 ! Lagrangian threshold
  real(dp),dimension(1:MAXLEVEL)::r_refine =-1.0 ! Radius of refinement region
  real(dp),dimension(1:MAXLEVEL)::x_refine = 0.0 ! Center of refinement region
  real(dp),dimension(1:MAXLEVEL)::y_refine = 0.0 ! Center of refinement region
  real(dp),dimension(1:MAXLEVEL)::z_refine = 0.0 ! Center of refinement region
  real(dp),dimension(1:MAXLEVEL)::exp_refine = 2.0 ! Exponent for distance
  real(dp),dimension(1:MAXLEVEL)::a_refine = 1.0 ! Ellipticity (Y/X)
  real(dp),dimension(1:MAXLEVEL)::b_refine = 1.0 ! Ellipticity (Z/X)
  real(dp)::var_cut_refine=-1.0 ! Threshold for variable-based refinement
  real(dp)::mass_cut_refine=-1.0 ! Mass threshold for particle-based refinement
  integer::ivar_refine=-1 ! Variable index for refinement
  logical::sink_refine=.false. ! Fully refine on sink particles

  ! Initial condition files for each level
  logical::multiple=.false.
  character(LEN=80),dimension(1:MAXLEVEL)::initfile=' '
  character(LEN=20)::filetype='ascii'

  ! Initial condition regions parameters
  integer,parameter::MAXREGION=100
  integer                           ::nregion=0
  character(LEN=10),dimension(1:MAXREGION)::region_type='square'
  real(dp),dimension(1:MAXREGION)   ::x_center=0.
  real(dp),dimension(1:MAXREGION)   ::y_center=0.
  real(dp),dimension(1:MAXREGION)   ::z_center=0.
  real(dp),dimension(1:MAXREGION)   ::length_x=1.E10
  real(dp),dimension(1:MAXREGION)   ::length_y=1.E10
  real(dp),dimension(1:MAXREGION)   ::length_z=1.E10
  real(dp),dimension(1:MAXREGION)   ::exp_region=2.0

  ! Boundary conditions parameters
  integer,parameter::MAXBOUND=100
  logical                           ::simple_boundary=.false.
  integer                           ::nboundary=0
  integer                           ::icoarse_min=0
  integer                           ::icoarse_max=0
  integer                           ::jcoarse_min=0
  integer                           ::jcoarse_max=0
  integer                           ::kcoarse_min=0
  integer                           ::kcoarse_max=0
  integer ,dimension(1:MAXBOUND)    ::boundary_type=0
  integer ,dimension(1:MAXBOUND)    ::ibound_min=0
  integer ,dimension(1:MAXBOUND)    ::ibound_max=0
  integer ,dimension(1:MAXBOUND)    ::jbound_min=0
  integer ,dimension(1:MAXBOUND)    ::jbound_max=0
  integer ,dimension(1:MAXBOUND)    ::kbound_min=0
  integer ,dimension(1:MAXBOUND)    ::kbound_max=0
  logical                           ::no_inflow=.false.

  !Number of processes sharing one token
  !Only one process can write at a time in an I/O group
  integer::IOGROUPSIZE=0           ! Main snapshot
  integer::IOGROUPSIZECONE=0       ! Lightcone
  integer::IOGROUPSIZEREP=0        ! Subfolder size
  logical::withoutmkdir=.false.    !If true mkdir should be done before the run
  logical::print_when_io=.false.   !If true print when IO
  logical::synchro_when_io=.false. !If true synchronize when IO

  ! Index for new SUM operator for MPI run
  integer::MPI_SUMDD

end module amr_parameters