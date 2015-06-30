module NScool_profile
   use NScool_def
   
   character(len=*), parameter :: scival = 'es15.6', intval = 'i15', fltval = 'f15.6'
   character(len=*), parameter :: filename_fmt = '(a,i0)'
   integer, parameter :: num_header_cols = 7, header_col_width=15
   integer, parameter :: num_profile_cols = 20, profile_col_width=15

   character(len=*), parameter :: header_count_fmt = '(7'//intval//')'
   character(len=*), parameter :: header_title_fmt = '(7a15)'
   character(len=*), parameter :: header_val_fmt = '('//intval//','//scival//',2'//fltval//',3'//scival//')'
   character(len=*), parameter :: profile_count_fmt = '(20'//intval//')'
   character(len=*), parameter :: profile_title_fmt = '(20a15)'
   character(len=*), parameter :: profile_val_fmt = &
   & '('//intval//',4'//scival//',2'//fltval//',4'//scival//',5'//fltval//',4'//scival//')'
   character(len=header_col_width), dimension(num_header_cols) :: header_cols = [character(len=header_col_width) ::  &
      & 'model', 'time', 'core_mass', 'core_radius', 'accretion_rate', 'heating_lum.', 'cooling_lum.']
   character(len=profile_col_width),dimension(num_profile_cols) :: profile_cols = [character(len=profile_col_width) ::  &
      & 'zone','mass','dm','area','gravity','eLambda','ePhi', &
      & 'temperature','luminosity','pressure','density', &
      & 'zbar','abar','Xn','Qimp', &
      & 'Gamma','cp','eps_nu','eps_nuc','K' ]
   
   logical, save :: profile_first_call = .TRUE.
   
   contains
   subroutine do_write_profile(id,ierr)
       use constants_def
      use utils_lib, only: alloc_iounit, free_iounit
      integer, intent(in) :: id
      integer, intent(out) :: ierr
      type(NScool_info), pointer :: s
      character(len=256) :: filename
      integer :: iounit, iz, ih
      real(dp) :: Lnu, Lnuc, grav
      character(len=16) ::profile_date, profile_time, profile_zone

      call get_NScool_info_ptr(id,s,ierr)
      if (ierr /= 0) return

      if (profile_first_call) then
          ! write header for profiles manifest
          open(newunit=iounit,file=trim(s% profile_manifest_filename), &
              & iostat=ierr)
          if (ierr /= 0) then
              write(*,*) 'failed to open profiles manifest ', &
                  & trim(s% profile_manifest_filename)
          else
              write(iounit,'(a15,a15,tr4,a)') 'model','time [s]', &
                  & 'base profile filename = '//trim(s% base_profile_filename)
              close(iounit)
          end if
          profile_first_call = .FALSE.
      end if
      
      write(filename,filename_fmt) trim(s% base_profile_filename), s% model
      
      iounit = alloc_iounit(ierr)
      if (ierr /= 0) return
      
      open(unit=iounit,file=trim(filename),action='write',iostat=ierr)
      if (ierr /= 0) then
         write(*,*) 'failed to open profile file ',trim(filename)
         return
      end if
      
      Lnu = dot_product(s% enu,s% dm)
      Lnuc = dot_product(s% enuc, s% dm)
      
      ! first line: write datestring
      call date_and_time(profile_date,profile_time,profile_zone)
      write (iounit,'(a,"/",2a,/)') trim(profile_date),trim(profile_time),trim(profile_zone)
      write (iounit,header_count_fmt) (ih, ih=1,num_header_cols)
      write (iounit,header_title_fmt) adjustr(header_cols)
      write (iounit,header_val_fmt) s% model, s% tsec, s% Mcore, s% Rcore, s% Mdot, Lnuc, Lnu
      write (iounit,*)
      write (iounit,*)
      write(iounit,profile_count_fmt) (ih, ih=1,num_profile_cols)
      write(iounit,profile_title_fmt) adjustr(profile_cols)
      do iz = 1, s% nz
          grav = fourpi*GMsun*s% Mcore*s% eLambda(iz)/s% area(iz)
         write(iounit,profile_val_fmt) iz, s% m(iz), s% dm(iz), s% area(iz), grav, s% eLambda(iz), s% ePhi(iz),  &
         &  s% T(iz), s% L(iz), s% P_bar(iz), s% rho(iz),  &
         &  s% ionic(iz)% Z, s% ionic(iz)% A, s% Xneut(iz),  s% ionic(iz)% Q, &
         &  s% Gamma(iz), s% Cp(iz), s% enu(iz), s% enuc(iz), s% Kcond(iz)
      end do
      
      close(iounit)
      
      ! now append to the manifest
      open(unit=iounit,file=trim(s% profile_manifest_filename), &
          & position='append',iostat=ierr)
      if (ierr /= 0) then
          write (*,*) 'unable to open profile manifest ', &
              & trim(s% profile_manifest_filename)
          return
      end if
      write (iounit,'(i15,es15.6)') s% model, s% tsec
      close(iounit)
      call free_iounit(iounit)
   end subroutine do_write_profile

end module NScool_profile
