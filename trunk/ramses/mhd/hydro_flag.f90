subroutine hydro_flag(ilevel)
  use amr_commons
  use hydro_commons
  implicit none
  integer::ilevel
  ! -------------------------------------------------------------------
  ! This routine flag for refinement cells that satisfies
  ! some user-defined physical criteria at the level ilevel. 
  ! -------------------------------------------------------------------
  integer::i,j,ncache,nok,ix,iy,iz,iskip
  integer::igrid,ind,idim,ngrid,ivar
  integer::nx_loc
  integer,dimension(1:nvector),save::ind_grid,ind_cell
  integer,dimension(1:nvector,0:twondim),save::igridn
  integer,dimension(1:nvector,1:twondim),save::indn

  logical,dimension(1:nvector),save::ok

  real(dp)::dx,dx_loc,scale
  real(dp),dimension(1:3)::skip_loc
  real(dp),dimension(1:twotondim,1:3)::xc
  real(dp),dimension(1:nvector,1:ndim),save::xx
  real(dp),dimension(1:nvector,1:nvar+3),save::uug,uum,uud

  if(ilevel==nlevelmax)return
  if(numbtot(1,ilevel)==0)return

  ! Rescaling factors
  dx=0.5d0**ilevel
  nx_loc=(icoarse_max-icoarse_min+1)
  skip_loc=(/0.0d0,0.0d0,0.0d0/)
  if(ndim>0)skip_loc(1)=dble(icoarse_min)
  if(ndim>1)skip_loc(2)=dble(jcoarse_min)
  if(ndim>2)skip_loc(3)=dble(kcoarse_min)
  scale=boxlen/dble(nx_loc)
  dx_loc=dx*scale

  ! Set position of cell centers relative to grid center
  do ind=1,twotondim
     iz=(ind-1)/4
     iy=(ind-1-4*iz)/2
     ix=(ind-1-2*iy-4*iz)
     if(ndim>0)xc(ind,1)=(dble(ix)-0.5D0)*dx
     if(ndim>1)xc(ind,2)=(dble(iy)-0.5D0)*dx
     if(ndim>2)xc(ind,3)=(dble(iz)-0.5D0)*dx
  end do

  if(    err_grad_d==-1.0.and.&
       & err_grad_p==-1.0.and.&
       & err_grad_A==-1.0.and.&
       & err_grad_B==-1.0.and.&
       & err_grad_C==-1.0.and.&
       & err_grad_E==-1.0.and.&
       & err_grad_B2==-1.0.and.&
       & err_grad_u==-1.0.and.&
       & jeans_refine(ilevel)==-1.0 )return

  ! Loop over active grids
  ncache=active(ilevel)%ngrid
  do igrid=1,ncache,nvector

     ! Gather nvector grids
     ngrid=MIN(nvector,ncache-igrid+1)
     do i=1,ngrid
        ind_grid(i)=active(ilevel)%igrid(igrid+i-1)
     end do

     ! Gather neighboring offsets
     call getnborgrids(ind_grid,igridn,ngrid)

     ! Loop over cells
     do ind=1,twotondim

        iskip=ncoarse+(ind-1)*ngridmax
        do i=1,ngrid
           ind_cell(i)=iskip+ind_grid(i)
        end do

        ! Initialize refinement to false
        do i=1,ngrid
           ok(i)=.false.
        end do

        ! Gather neighboring cells
        call getnborcells(igridn,ind,indn,ngrid)

        ! If a neighbor cell does not exist,
        ! replace it by its father cell
        do j=1,twondim
           do i=1,ngrid
              if(indn(i,j)==0)then
                 indn(i,j)=nbor(ind_grid(i),j)
              end if
           end do
        end do

        ! Loop over dimensions
        do idim=1,ndim
           ! Gather hydro variables
           do ivar=1,nvar+3
              do i=1,ngrid
                 uug(i,ivar)=uold(indn(i,2*idim-1),ivar)
                 uum(i,ivar)=uold(ind_cell(i     ),ivar)
                 uud(i,ivar)=uold(indn(i,2*idim  ),ivar)
              end do
           end do
           call hydro_refine(uug,uum,uud,ok,ngrid,ilevel)
        end do
     
        if(poisson.and.jeans_refine(ilevel)>0.0)then
           call jeans_length_refine(ind_cell,ok,ngrid,ilevel)
        endif

        ! Apply geometry-based refinement criteria
        if(r_refine(ilevel)>-1.0)then
           ! Compute cell center in code units
           do idim=1,ndim
              do i=1,ngrid
                 xx(i,idim)=xg(ind_grid(i),idim)+xc(ind,idim)
              end do
           end do
           ! Rescale position from code units to user units
           do idim=1,ndim
              do i=1,ngrid
                 xx(i,idim)=(xx(i,idim)-skip_loc(idim))*scale
              end do
           end do
           call geometry_refine(xx,ind_cell,ok,ngrid,ilevel)
        end if

        ! Count newly flagged cells
        nok=0
        do i=1,ngrid
           if(flag1(ind_cell(i))==0.and.ok(i))then
              nok=nok+1
           end if
        end do
     
        do i=1,ngrid
           if(ok(i))flag1(ind_cell(i))=1
        end do
        
        nflag=nflag+nok
     end do
     ! End loop over cells
     
  end do
  ! End loop over grids

end subroutine hydro_flag
!#####################################################################
!#####################################################################
!#####################################################################
!#####################################################################
subroutine jeans_length_refine(ind_cell,ok,ncell,ilevel)
  use amr_commons
  use pm_commons
  use hydro_commons
  use poisson_commons
  use cooling_module, ONLY: twopi
  use units_commons
  implicit none
  integer::ncell,ilevel,irad
  integer,dimension(1:nvector)::ind_cell
  logical,dimension(1:nvector)::ok
  !-------------------------------------------------
  ! This routine sets flag1 to 1 if cell statisfy
  ! user-defined physical criterion for refinement.
  ! P. Hennebelle 03/11/2005
  !-------------------------------------------------
  integer::i,indi
  real(dp)::lamb_jeans,tail_pix,pi,n_jeans
  real(dp)::dens,tempe,emag,etherm,factG
  real(dp)::iso_etherm,iso_cs,iso_cs2,rho_star,rho_iso,tempe2

  rho_iso  = 1.0e-08_dp
  rho_star = 1.0e-05_dp
  
  pi = twopi / 2.
  factG=1.0d0
  if(cosmo)factG=3d0/8d0/pi*omega_m*aexp
  n_jeans = jeans_refine(ilevel)
  ! compute the size of the pixel
  tail_pix = boxlen / (2.d0)**ilevel
  do i=1,ncell
     indi = ind_cell(i)
     ! the thermal energy
     dens = max(uold(indi,1),smallr)
     etherm = uold(indi,5) 
     etherm = etherm - 0.5d0*uold(indi,2)**2/dens
     etherm = etherm - 0.5d0*uold(indi,3)**2/dens
     etherm = etherm - 0.5d0*uold(indi,4)**2/dens
     ! the magnetic energy
     emag =        (uold(indi,6)+uold(indi,nvar+1))**2
     emag = emag + (uold(indi,7)+uold(indi,nvar+2))**2
     emag = emag + (uold(indi,8)+uold(indi,nvar+3))**2
     emag = emag / 8.d0
     etherm = (etherm - emag) 
#if NENER>0
     do irad=1,nener
        etherm=etherm-uold(indi,8+irad)
     end do
#endif
     ! the temperature
!     tempe =  etherm / dens * (gamma -1.0)
     call soundspeed_eos(dens,etherm,tempe)
     tempe=tempe**2
     ! prevent numerical crash due to negative temperature
     tempe = max(tempe,smallc**2)
     tempe2 = tempe
     if(iso_jeans .and. (dens*scale_d .lt. rho_star)) then
        ! Isothermal spound speed based jeans criterion (quite expensive....)
        call enerint_eos(dens,Tp_jeans,iso_etherm)
        call soundspeed_eos(dens,iso_etherm,iso_cs)
!        iso_cs=iso_cs**2
!        tempe=min(tempe,iso_cs)
        iso_cs2=iso_cs**2
        tempe=min(tempe,iso_cs2)
!       if(dens*scale_d .gt. 1.d-8)then
!           ! Here we increase back the sound speed once 2nd collapse has started
!           ! Cs_eos does not depend so much on density, so we start back at cs_iso
!           call soundspeed_eos(dens,etherm,tempe)
!           dens_max=1.d-8/scale_d
!           call soundspeed_eos(dens_max,etherm,tempe2)
!           iso_cs=iso_cs+(tempe-tempe2)
!           iso_cs2=iso_cs**2
!           tempe=iso_cs2
!        end if
        if(dens*scale_d .gt. rho_iso)then
           ! Here we increase back the sound speed once 2nd collapse has started
           ! Cs_eos does not depend so much on density, so we start back at cs_iso
           !!call soundspeed_eos(dens,etherm,tempe)
!           dens_max=1.d-8/scale_d
!           call soundspeed_eos(dens_max,etherm,tempe2)
           iso_cs=10.0_dp**(log10(tempe2) - (log10(tempe2)-log10(iso_cs))*((log10(rho_star) - log10(dens*scale_d))/(log10(rho_star) - log10(rho_iso))))
           iso_cs2=iso_cs**2
           tempe=iso_cs2
        end if
     endif

     ! compute the Jeans length (remember G=1)
     lamb_jeans = sqrt( tempe * pi / dens / factG )  
     ! the Jeans length must be smaller
     ! than n_jeans times the size of the pixel
     ok(i) = ok(i) .or. ( n_jeans*tail_pix >= lamb_jeans )
  end do

end subroutine jeans_length_refine
