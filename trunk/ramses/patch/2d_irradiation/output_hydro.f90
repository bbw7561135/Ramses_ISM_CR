subroutine file_descriptor_hydro(filename)
  use amr_commons
  use hydro_commons
  use rt_hydro_commons
  use rt_parameters
  implicit none
#ifndef WITHOUTMPI
  include 'mpif.h'
#endif

  character(LEN=80)::filename
  character(LEN=80)::fileloc
  integer::ivar,ilun

  if(verbose)write(*,*)'Entering file_descriptor_hydro'

  ilun=11

  ! Open file
  fileloc=TRIM(filename)
  open(unit=ilun,file=fileloc,form='formatted')

  ! Write run parameters
  write(ilun,'("nvar        =",I11)')nvar+4+NGroups*(ndim+1)
  ivar=1
  write(ilun,'("variable #",I2,": density")')ivar
  ivar=2
  write(ilun,'("variable #",I2,": velocity_x")')ivar
  ivar=3
  write(ilun,'("variable #",I2,": velocity_y")')ivar
  ivar=4
  write(ilun,'("variable #",I2,": velocity_z")')ivar
  ivar=5
  write(ilun,'("variable #",I2,": B_left_x")')ivar
  ivar=6
  write(ilun,'("variable #",I2,": B_left_y")')ivar
  ivar=7
  write(ilun,'("variable #",I2,": B_left_z")')ivar
  ivar=8
  write(ilun,'("variable #",I2,": B_right_x")')ivar
  ivar=9
  write(ilun,'("variable #",I2,": B_right_y")')ivar
  ivar=10
  write(ilun,'("variable #",I2,": B_right_z")')ivar
#if NENER>NGRP
  ! Non-thermal pressures
  do ivar=1,nent
     write(ilun,'("variable #",I2,": non_thermal_pressure_",I1)')10+ivar,ivar
  end do
#endif
  ivar=11+nent
  write(ilun,'("variable #",I2,": thermal_pressure")')ivar
#if NGRP>0
  ! Radiative energies
  do ivar=1,ngrp
     write(ilun,'("variable #",I2,": radiative_energy_",I1)')firstindex_er+3+ivar,ivar
  end do
#endif
#if USE_M_1==1
  ! Radiative fluxes
  do ivar=1,ngrp
     write(ilun,'("variable #",I2,": radiative_flux_x",I1)')firstindex_fr+3       +ivar,ivar
  end do
if(ndim>1) then
  do ivar=1,ngrp
     write(ilun,'("variable #",I2,": radiative_flux_y",I1)')firstindex_fr+3+  ngrp+ivar,ivar
  end do
endif
if(ndim>2) then
  do ivar=1,ngrp
     write(ilun,'("variable #",I2,": radiative_flux_z",I1)')firstindex_fr+3+2*ngrp+ivar,ivar
  end do
endif
#endif
#if NEXTINCT>0
  ! Extinction
  do ivar=1,nextinct
     write(ilun,'("variable #",I2,": extinction",I1)')firstindex_extinct+3+ivar,ivar
  end do
#endif
#if NPSCAL>0
  ! Passive scalars
  do ivar=1,npscal
     write(ilun,'("variable #",I2,": passive_scalar_",I1)')firstindex_pscal+3+ivar,ivar
  end do
#endif
  ! Temperature
  ivar=firstindex_pscal+3+npscal+1
  write(ilun,'("variable #",I2,": temperature")')ivar


#ifdef RT
  do ivar=1,nGroups
     write(ilun,'("variable #",I2,": photon_number_flux_",I1)')nvar+4+ivar,ivar
     write(ilun,'("variable #",I2,": photon_number_xflux_",I1)')nvar+4+ivar+1,ivar
     write(ilun,'("variable #",I2,": photon_number_yflux_",I1)')nvar+4+ivar+2,ivar
     write(ilun,'("variable #",I2,": photon_number_zflux_",I1)')nvar+4+ivar+3,ivar
  end do
#endif

  close(ilun)

end subroutine file_descriptor_hydro

subroutine backup_hydro(filename)
  use amr_commons
  use hydro_commons
  use rt_hydro_commons
  use rt_parameters
  implicit none
#ifndef WITHOUTMPI
  include 'mpif.h'  
#endif
  character(LEN=80)::filename

  integer::i,ivar,ncache,ind,ilevel,igrid,iskip,ilun,istart,ibound,irad,ht,idim
  integer,allocatable,dimension(:)::ind_grid
  real(dp)::d,u,v,w,A,B,C,e,cmp_temp,p
  real(dp),allocatable,dimension(:)::xdp
  character(LEN=5)::nchar
  character(LEN=80)::fileloc
  integer,parameter::tag=1121
  integer::dummy_io,info2

  if(verbose)write(*,*)'Entering backup_hydro'

  ilun=ncpu+myid+10
     
  call title(myid,nchar)
  fileloc=TRIM(filename)//TRIM(nchar)
 
  ! Wait for the token
#ifndef WITHOUTMPI
  if(IOGROUPSIZE>0) then
     if (mod(myid-1,IOGROUPSIZE)/=0) then
        call MPI_RECV(dummy_io,1,MPI_INTEGER,myid-1-1,tag,&
             & MPI_COMM_WORLD,MPI_STATUS_IGNORE,info2)
     end if
  endif
#endif
  open(unit=ilun,file=fileloc,form='unformatted')
  write(ilun)ncpu
!   if(eos) then 
!      write(ilun)nvar+3+1
!   else
!      write(ilun)nvar+3
!   endif
  write(ilun)nvar+4+NGroups*(ndim+1)
  write(ilun)ndim
  write(ilun)nlevelmax
  write(ilun)nboundary
  write(ilun)gamma
  do ilevel=1,nlevelmax
     do ibound=1,nboundary+ncpu
        if(ibound<=ncpu)then
           ncache=numbl(ibound,ilevel)
           istart=headl(ibound,ilevel)
        else
           ncache=numbb(ibound-ncpu,ilevel)
           istart=headb(ibound-ncpu,ilevel)
        end if
        write(ilun)ilevel
        write(ilun)ncache
        if(ncache>0)then
           allocate(ind_grid(1:ncache),xdp(1:ncache))
           ! Loop over level grids
           igrid=istart
           do i=1,ncache
              ind_grid(i)=igrid
              igrid=next(igrid)
           end do
           ! Loop over cells
           do ind=1,twotondim
              iskip=ncoarse+(ind-1)*ngridmax
              do ivar=1,4
                 if(ivar==1)then ! Write density
                    do i=1,ncache
                       xdp(i)=uold(ind_grid(i)+iskip,1)
                    end do
                 else ! Write velocity field
                    do i=1,ncache
                       xdp(i)=uold(ind_grid(i)+iskip,ivar)/max(uold(ind_grid(i)+iskip,1),smallr)
                    end do
                 endif
                 write(ilun)xdp
              end do
              do ivar=6,8 ! Write left B field
                 do i=1,ncache
                    xdp(i)=uold(ind_grid(i)+iskip,ivar)
                 end do
                 write(ilun)xdp
              end do
              do ivar=nvar+1,nvar+3 ! Write right B field
                 do i=1,ncache
                    xdp(i)=uold(ind_grid(i)+iskip,ivar)
                 end do
                 write(ilun)xdp
              end do
#if NENER>NGRP
              ! Write non-thermal pressures
              do ivar=1,nent
                 do i=1,ncache
                    xdp(i)=(gamma_rad(ivar)-1d0)*uold(ind_grid(i)+iskip,8+ivar)
                 end do
                 write(ilun)xdp
              end do
#endif
              do i=1,ncache ! Write thermal pressure
                 d=max(uold(ind_grid(i)+iskip,1),smallr)
                 u=uold(ind_grid(i)+iskip,2)/d
                 v=uold(ind_grid(i)+iskip,3)/d
                 w=uold(ind_grid(i)+iskip,4)/d
                 A=0.5*(uold(ind_grid(i)+iskip,6)+uold(ind_grid(i)+iskip,nvar+1))
                 B=0.5*(uold(ind_grid(i)+iskip,7)+uold(ind_grid(i)+iskip,nvar+2))
                 C=0.5*(uold(ind_grid(i)+iskip,8)+uold(ind_grid(i)+iskip,nvar+3))
                 e=uold(ind_grid(i)+iskip,5)-0.5*d*(u**2+v**2+w**2)-0.5*(A**2+B**2+C**2)
#if NENER>0
                 do irad=1,nener
                    e=e-uold(ind_grid(i)+iskip,8+irad)
                 end do
#endif
                 call pressure_eos(d,e,p)
                 xdp(i)=p
              end do
              write(ilun)xdp

#if NGRP>0
              do ivar=1,ngrp ! Write radiative energy if any
                 do i=1,ncache
                    xdp(i)=uold(ind_grid(i)+iskip,firstindex_er+ivar)
                 end do
                 write(ilun)xdp
              end do
#if USE_M_1==1
              do ivar=1,nfr ! Write radiative flux if any
                 do i=1,ncache
                    xdp(i)=uold(ind_grid(i)+iskip,firstindex_fr+ivar)
                 end do
                 write(ilun)xdp
              end do
#endif
#endif
#if NEXTINCT>0
              ! Write extinction if activated
              do i=1,ncache
                 xdp(i)=uold(ind_grid(i)+iskip,firstindex_nextinct+1)
              end do
              write(ilun)xdp
#endif

#if NPSCAL>0
              do ivar=1,npscal ! Write passive scalars if any
                 do i=1,ncache
                    xdp(i)=uold(ind_grid(i)+iskip,firstindex_pscal+ivar)/max(uold(ind_grid(i)+iskip,1),smallr)
                 end do
                 write(ilun)xdp
              end do
#endif             
              ! Write temperature
              do i=1,ncache
                 d=max(uold(ind_grid(i)+iskip,1),smallr)
                 if(energy_fix) then
                    e=uold(ind_grid(i)+iskip,nvar)
                 else
                    u=uold(ind_grid(i)+iskip,2)/d
                    v=uold(ind_grid(i)+iskip,3)/d
                    w=uold(ind_grid(i)+iskip,4)/d
                    A=0.5*(uold(ind_grid(i)+iskip,6)+uold(ind_grid(i)+iskip,nvar+1))
                    B=0.5*(uold(ind_grid(i)+iskip,7)+uold(ind_grid(i)+iskip,nvar+2))
                    C=0.5*(uold(ind_grid(i)+iskip,8)+uold(ind_grid(i)+iskip,nvar+3))
                    e=uold(ind_grid(i)+iskip,5)-0.5*d*(u**2+v**2+w**2)-0.5*(A**2+B**2+C**2)
#if NENER>0
                    do irad=1,nener
                       e=e-uold(ind_grid(i)+iskip,8+irad)
                    end do
#endif
                 endif
                 call temperature_eos(d,e,cmp_temp,ht)
                 xdp(i)=cmp_temp
              end do
              write(ilun)xdp

#ifdef RT      
              do ivar=1,nGroups
                 ! Store photon density in flux units
                 do i=1,ncache
                    xdp(i)=rt_c*rtuold(ind_grid(i)+iskip,iGroups(ivar))
                 end do
                 write(ilun)xdp
                 do idim=1,ndim
                    ! Store photon flux
                    do i=1,ncache
                       xdp(i)=rtuold(ind_grid(i)+iskip,iGroups(ivar)+idim)
                    end do
                    write(ilun)xdp
                 enddo
              end do
#endif 
           end do
           deallocate(ind_grid, xdp)
        end if
     end do
  end do
  close(ilun)
  ! Send the token
#ifndef WITHOUTMPI
  if(IOGROUPSIZE>0) then
     if(mod(myid,IOGROUPSIZE)/=0 .and.(myid.lt.ncpu))then
        dummy_io=1
        call MPI_SEND(dummy_io,1,MPI_INTEGER,myid-1+1,tag, &
             & MPI_COMM_WORLD,info2)
     end if
  endif
#endif
    
end subroutine backup_hydro





