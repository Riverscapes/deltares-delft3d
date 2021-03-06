subroutine wrsedh(lundia    ,error     ,trifil    ,ithisc    , &
                & nostat    ,kmax      ,lsed      ,lsedtot   , &
                & zws       ,zrsdeq    ,zbdsed    ,zdpsed    ,zdps      , &
                & ntruv     , &
                & zsbu      ,zsbv      ,zssu      ,zssv      ,sbtr      , &
                & sstr      ,sbtrc     ,sstrc     ,zrca      ,gdp       )
!----- GPL ---------------------------------------------------------------------
!                                                                               
!  Copyright (C)  Stichting Deltares, 2011-2012.                                
!                                                                               
!  This program is free software: you can redistribute it and/or modify         
!  it under the terms of the GNU General Public License as published by         
!  the Free Software Foundation version 3.                                      
!                                                                               
!  This program is distributed in the hope that it will be useful,              
!  but WITHOUT ANY WARRANTY; without even the implied warranty of               
!  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the                
!  GNU General Public License for more details.                                 
!                                                                               
!  You should have received a copy of the GNU General Public License            
!  along with this program.  If not, see <http://www.gnu.org/licenses/>.        
!                                                                               
!  contact: delft3d.support@deltares.nl                                         
!  Stichting Deltares                                                           
!  P.O. Box 177                                                                 
!  2600 MH Delft, The Netherlands                                               
!                                                                               
!  All indications and logos of, and references to, "Delft3D" and "Deltares"    
!  are registered trademarks of Stichting Deltares, and remain the property of  
!  Stichting Deltares. All rights reserved.                                     
!                                                                               
!-------------------------------------------------------------------------------
!  $Id: wrsedh.f90 2163 2013-02-01 13:30:53Z mourits $
!  $HeadURL: https://svn.oss.deltares.nl/repos/delft3d/tags/5.01.00.2163/src/engines_gpl/flow2d3d/packages/io/src/output/wrsedh.f90 $
!!--description-----------------------------------------------------------------
!
!    Function: Writes the time varying data for sediment (4 & 5)
!              to the NEFIS HIS-DAT file.
!              Output is performed conform the times of history
!              file and only in case lsed > 0.
! Method used:
!
!!--pseudo code and references--------------------------------------------------
! NONE
!!--declarations----------------------------------------------------------------
    use precision
    use sp_buffer
    !
    use globaldata
    !
    implicit none
    !
    type(globdat),target :: gdp
    !
    ! The following list of pointer parameters is used to point inside the gdp structure
    !
    integer                              , pointer :: celidt
    integer       , dimension(:)         , pointer :: line_orig
    integer       , dimension(:)         , pointer :: shlay
    real(hp)                             , pointer :: morft
    real(fp)                             , pointer :: morfac
    real(fp)                             , pointer :: sus
    real(fp)                             , pointer :: bed
    real(fp)      , dimension(:)         , pointer :: rhosol
    real(fp)      , dimension(:)         , pointer :: cdryb
    logical                              , pointer :: first
    type (moroutputtype)                 , pointer :: moroutput
    type (nefiselement)                  , pointer :: nefiselem
!
! Global variables
!
    integer                             , intent(in)  :: ithisc !!  Current time counter for the history data file
    integer                                           :: ithisi !  Description and declaration in inttim.igs
    integer                                           :: itstrt !  Description and declaration in inttim.igs
    integer                                           :: kmax   !  Description and declaration in esm_alloc_int.f90
    integer                                           :: lsed   !  Description and declaration in esm_alloc_int.f90
    integer                                           :: lsedtot!  Description and declaration in esm_alloc_int.f90
    integer                                           :: lundia !  Description and declaration in inout.igs
    integer                                           :: nostat !  Description and declaration in dimens.igs
    integer                                           :: ntruv  !  Description and declaration in dimens.igs
    logical                             , intent(out) :: error  !!  Flag=TRUE if an error is encountered
    real(fp), dimension(nostat)                       :: zdps   !  Description and declaration in esm_alloc_real.f90
    real(fp), dimension(nostat)                       :: zdpsed !  Description and declaration in esm_alloc_real.f90
    real(fp), dimension(nostat, 0:kmax, lsed)         :: zws    !  Description and declaration in esm_alloc_real.f90
    real(fp), dimension(nostat, kmax, lsed)           :: zrsdeq !  Description and declaration in esm_alloc_real.f90
    real(fp), dimension(nostat, lsedtot)              :: zbdsed !  Description and declaration in esm_alloc_real.f90
    real(fp), dimension(nostat, lsed)                 :: zrca   !  Description and declaration in esm_alloc_real.f90
    real(fp), dimension(nostat, lsedtot), intent(in)  :: zsbu   !  Description and declaration in esm_alloc_real.f90
    real(fp), dimension(nostat, lsedtot), intent(in)  :: zsbv   !  Description and declaration in esm_alloc_real.f90
    real(fp), dimension(nostat, lsed)   , intent(in)  :: zssu   !  Description and declaration in esm_alloc_real.f90
    real(fp), dimension(nostat, lsed)   , intent(in)  :: zssv   !  Description and declaration in esm_alloc_real.f90
    real(fp), dimension(ntruv, lsedtot) , intent(in)  :: sbtr   !  Description and declaration in esm_alloc_real.f90
    real(fp), dimension(ntruv, lsedtot) , intent(in)  :: sbtrc  !  Description and declaration in esm_alloc_real.f90
    real(fp), dimension(ntruv, lsed)    , intent(in)  :: sstr   !  Description and declaration in esm_alloc_real.f90
    real(fp), dimension(ntruv, lsed)    , intent(in)  :: sstrc  !  Description and declaration in esm_alloc_real.f90
    character(60)                       , intent(in)  :: trifil !!  File name for FLOW NEFIS output files (tri"h/m"-"casl""labl".dat/def)
!
! Local variables
!
    real(sp)                           :: sdummy
    real(fp)                           :: rhol
    integer                            :: fds
    integer                            :: i              ! Help var. 
    integer                            :: ierror         ! Local errorflag for NEFIS files
    integer                            :: istat
    integer                            :: k
    integer                            :: kmaxout        ! number of layers to be written to the (history) output files, 0 (possibly) included
    integer                            :: kmaxout_restr  ! number of layers to be written to the (history) output files, 0 excluded
    integer                            :: l
    integer                            :: n
    integer, dimension(:), allocatable :: norig
    integer, dimension(1)              :: idummy         ! Help array to read/write Nefis files
    integer, dimension(3,5)            :: uindex
    integer, dimension(:), allocatable :: shlay_restr    ! work array
    integer, external                  :: getelt
    integer, external                  :: putelt
    integer, external                  :: inqmxi
    integer, external                  :: clsnef
    integer, external                  :: open_datdef
    integer, external                  :: neferr
    character(2)                       :: sedunit
    character(10)                      :: transpunit
    character(16)                      :: grnam4
    character(16)                      :: grnam5
    character(256)                     :: errmsg         ! Character var. containing the errormessage to be written to file. The message depends on the error. 
    character(60)                      :: filnam         ! Help var. for FLOW file name 
!
! Data statements
!
    data grnam4/'his-infsed-serie'/
    data grnam5/'his-sed-series'/
!
!! executable statements -------------------------------------------------------
!
    nefiselem  => gdp%nefisio%nefiselem(nefiswrsedhinf)
    line_orig  => gdp%gdstations%line_orig
    shlay      => gdp%gdpostpr%shlay
    celidt     => nefiselem%celidt
    morft      => gdp%gdmorpar%morft
    morfac     => gdp%gdmorpar%morfac
    sus        => gdp%gdmorpar%sus
    bed        => gdp%gdmorpar%bed
    rhosol     => gdp%gdsedpar%rhosol
    cdryb      => gdp%gdsedpar%cdryb
    first      => nefiselem%first
    moroutput  => gdp%gdmorpar%moroutput
    !
    kmaxout = size(shlay)
    if (shlay(1) == 0) then
       kmaxout_restr = kmaxout - 1
       allocate(shlay_restr(kmaxout_restr))
       shlay_restr   = shlay(2:)
    else
       kmaxout_restr = kmaxout
       allocate(shlay_restr(kmaxout_restr))
       shlay_restr   = shlay
    endif
    filnam  = trifil(1:3) // 'h' // trifil(5:)
    errmsg  = ' '
    !
    ! initialize group index time dependent data
    !
    uindex (1,1) = 1 ! start index
    uindex (2,1) = 1 ! end index
    uindex (3,1) = 1 ! increment in time
    !
    if (first) then
       !
       ! Set up the element characteristics
       !
       select case(moroutput%transptype)
       case (0)
          sedunit = 'KG'
       case (1)
          sedunit = 'M3'
       case (2)
          sedunit = 'M3'
       end select
       !
       ! his-infsed-serie
       !
       call addelm(nefiswrsedhinf,'ITHISS',' ','[   -   ]','INTEGER',4     , &
         & 'timestep number (ITHISS*DT*TUNIT := time in sec from ITDATE)  ', &
         &  1         ,1         ,0         ,0         ,0         ,0       , &
         &  lundia    ,gdp       )
       call addelm(nefiswrsedhinf,'MORFAC',' ','[   -   ]','REAL',4        , &
         & 'morphological acceleration factor (MORFAC)                    ', &
         &  1         ,1         ,0         ,0         ,0         ,0       , &
         &  lundia    ,gdp       )
       call addelm(nefiswrsedhinf,'MORFT',' ','[ DAYS  ]','REAL',8         , &
         & 'morphological time (days since start of simulation)           ', &
         &  1         ,1         ,0         ,0         ,0         ,0       , &
         &  lundia    ,gdp       )
       call defnewgrp(nefiswrsedhinf ,filnam    ,grnam4   ,gdp)
       !
       ! his-sed-series: stations
       !
       if (nostat > 0) then
         if (lsed > 0) then
           call addelm(nefiswrsedh,'ZWS',' ','[  M/S  ]','REAL',4              , &
             & 'Settling velocity in station                                  ', &
             &  3         ,nostat    ,kmaxout   ,lsed      ,0         ,0       , &
             &  lundia    ,gdp       )
           if (kmax == 1) then
             call addelm(nefiswrsedh,'ZRSDEQ',' ','[ KG/M3 ]','REAL',4           , &
               & 'Equilibrium concentration of sediment at station (2D only)    ', &
               &  3         ,nostat    ,kmaxout_restr,lsed      ,0         ,0       , &
               &  lundia    ,gdp       )
           endif
         endif
         call addelm(nefiswrsedh,'ZBDSED',' ','[ KG/M2 ]','REAL',4           , &
           & 'Available mass of sediment at bed at station                  ', &
           &  2         ,nostat    ,lsedtot   ,0         ,0         ,0       , &
           &  lundia    ,gdp       )
         call addelm(nefiswrsedh,'ZDPSED',' ','[   M   ]','REAL',4           , &
           & 'Sediment thickness at bed at station (zeta point)             ', &
           &  1         ,nostat    ,0         ,0         ,0         ,0       , &
           &  lundia    ,gdp       )
         call addelm(nefiswrsedh,'ZDPS',' ','[   M   ]','REAL',4             , &
           & 'Morphological depth at station (zeta point)                   ', &
           &  1         ,nostat    ,0         ,0         ,0         ,0       , &
           &  lundia    ,gdp       )
         transpunit = '[ ' // sedunit // '/S/M]'
         call addelm(nefiswrsedh,'ZSBU',' ',transpunit ,'REAL',4             , &
           & 'Bed load transport in u-direction at station (zeta point)     ', &
           &  2         ,nostat    ,lsedtot   ,0         ,0         ,0       , &
           &  lundia    ,gdp       )
         call addelm(nefiswrsedh,'ZSBV',' ',transpunit ,'REAL',4             , &
           & 'Bed load transport in v-direction at station (zeta point)     ', &
           &  2         ,nostat    ,lsedtot   ,0         ,0         ,0       , &
           &  lundia    ,gdp       )
         if (lsed > 0) then
           call addelm(nefiswrsedh,'ZSSU',' ',transpunit ,'REAL',4             , &
             & 'Susp. load transport in u-direction at station (zeta point)   ', &
             &  2         ,nostat    ,lsed      ,0         ,0         ,0       , &
             &  lundia    ,gdp       )
           call addelm(nefiswrsedh,'ZSSV',' ',transpunit ,'REAL',4             , &
             & 'Susp. load transport in v-direction at station (zeta point)   ', &
             &  2         ,nostat    ,lsed      ,0         ,0         ,0       , &
             &  lundia    ,gdp       )
           call addelm(nefiswrsedh,'ZRCA',' ','[ KG/M3 ]','REAL',4             , &
             & 'Near-bed reference concentration of sediment at station       ', &
             &  2         ,nostat    ,lsed      ,0         ,0         ,0       , &
             &  lundia    ,gdp       )
         endif
       endif
       !
       ! his-sed-series: cross-sections
       !
       if (ntruv > 0) then
         transpunit = '[ ' // sedunit // '/S  ]'
         call addelm(nefiswrsedh,'SBTR',' ',transpunit ,'REAL',4             , &
           & 'Instantaneous bed load transport through section              ', &
           &  2         ,ntruv     ,lsedtot   ,0         ,0         ,0       , &
           &  lundia    ,gdp       )
         if (lsed > 0) then         
           call addelm(nefiswrsedh,'SSTR',' ',transpunit ,'REAL',4             , &
             & 'Instantaneous susp. load transport through section            ', &
             &  2         ,ntruv     ,lsed      ,0         ,0         ,0       , &
             &  lundia    ,gdp       )
         endif
         transpunit = '[  ' // sedunit // '   ]'
         call addelm(nefiswrsedh,'SBTRC',' ',transpunit ,'REAL',4            , &
           & 'Cumulative bed load transport through section                 ', &
           &  2         ,ntruv     ,lsedtot   ,0         ,0         ,0       , &
           &  lundia    ,gdp       )
         if (lsed > 0) then
           call addelm(nefiswrsedh,'SSTRC',' ',transpunit ,'REAL',4            , &
             & 'Cumulative susp. load transport through section               ', &
             &  2         ,ntruv     ,lsed      ,0         ,0         ,0       , &
             &  lundia    ,gdp       )
         endif
       endif
       !
       call defnewgrp(nefiswrsedh ,filnam    ,grnam5   ,gdp)
       !
       ! Get start celidt for writing
       !
       nefiselem => gdp%nefisio%nefiselem(nefiswrsedhinf)
    first               => nefiselem%first
    celidt              => nefiselem%celidt
    endif
    !
    ierror = open_datdef(filnam   ,fds      )
    if (ierror/= 0) goto 9999
    if (first) then
       !
       ! end of initialization, don't come here again
       !
       ierror = inqmxi(fds, grnam4, celidt)
       first = .false.
    endif
    !
    ! Writing of output on every ithisc
    !
    celidt = celidt + 1
    !
    idummy(1)   = ithisc
    uindex(1,1) = celidt
    uindex(2,1) = celidt
    !
    ! Group his-sed-series, identified with nefiswrsedh, must use the same
    ! value for celidt.
    ! Easy solution:
    gdp%nefisio%nefiselem(nefiswrsedh)%celidt = celidt
    ! Neat solution in pseudo code:
    ! subroutine wrsedh
    !    integer :: celidt
    !    call wrsedhinf(celidt)
    !    call wrsedhdat(celidt)
    ! end subroutine
    !
    ierror     = putelt(fds, grnam4, 'ITHISS', uindex, 1, idummy)
    if (ierror/= 0) goto 9999
    !
    sdummy      = real(morfac,sp)
    ierror     = putelt(fds, grnam4, 'MORFAC', uindex, 1, sdummy)
    if (ierror/= 0) goto 9999
    !
    ! MORFT is a double!
    !
    ierror     = putelt(fds, grnam4, 'MORFT', uindex, 1, morft)
    if (ierror/= 0) goto 9999
    !
    ! his-sed-series: stations
    !
    if (nostat > 0) then
       if (lsed > 0) then     
          !
          ! group 5: element 'ZWS'
          !
          call sbuff_checksize(nostat*(kmaxout)*lsed)
          i = 0
          do l = 1, lsed
             do k = 1, kmaxout
                do n = 1, nostat
                   i        = i+1
                   sbuff(i) = real(zws(n, shlay(k), l),sp)
                enddo
             enddo
          enddo
          ierror = putelt(fds, grnam5, 'ZWS', uindex, 1, sbuff)
          if (ierror/= 0) goto 9999
          if (kmax == 1) then
             !
             ! group 5: element 'ZRSDEQ'
             ! kmax=1: don't use kmaxout/shlay
             !
             call sbuff_checksize(nostat*kmax*lsed)
             i = 0
             do l = 1, lsed
                do k = 1, kmax
                   do n = 1, nostat
                      i        = i+1
                      sbuff(i) = real(zrsdeq(n, k, l),sp)
                   enddo
                enddo
             enddo
             ierror = putelt(fds, grnam5, 'ZRSDEQ', uindex, 1, sbuff)
             if (ierror/= 0) goto 9999
          endif
       endif
       !
       ! group 5: element 'ZBDSED'
       !
       call sbuff_checksize(nostat*lsedtot)
       i = 0
       do l = 1, lsedtot
          do n = 1, nostat
             i        = i+1
             sbuff(i) = real(zbdsed(n, l),sp)
          enddo
       enddo
       ierror = putelt(fds, grnam5, 'ZBDSED', uindex, 1, sbuff)
       if (ierror/= 0) goto 9999
       !
       ! group 5: element 'ZDPSED'
       !
       call sbuff_checksize(nostat)
       i = 0
       do n = 1, nostat
          i        = i+1
          sbuff(i) = real(zdpsed(n),sp)
       enddo
       ierror = putelt(fds, grnam5, 'ZDPSED', uindex, 1, sbuff)
       if (ierror/= 0) goto 9999
       !
       ! group 5: element 'ZDPS'
       !
       call sbuff_checksize(nostat)
       i = 0
       do n = 1, nostat
          i        = i+1
          sbuff(i) = real(zdps(n),sp)
       enddo
       ierror = putelt(fds, grnam5, 'ZDPS', uindex, 1, sbuff)
       if (ierror/= 0) goto 9999
       !
       ! group 5: element 'ZSBU'
       !
       call sbuff_checksize(nostat*lsedtot)
       i = 0
       do l = 1, lsedtot
          select case(moroutput%transptype)
          case (0)
             rhol = 1.0_fp
          case (1)
             rhol = cdryb(l)
          case (2)
             rhol = rhosol(l)
          end select
          do n = 1, nostat
             i        = i+1
             sbuff(i) = real(zsbu(n, l)/rhol,sp)
          enddo
       enddo
       ierror = putelt(fds, grnam5, 'ZSBU', uindex, 1, sbuff)
       if (ierror/= 0) goto 9999
       !
       ! group 5: element 'ZSBV'
       !
       call sbuff_checksize(nostat*lsedtot)
       i = 0
       do l = 1, lsedtot
          select case(moroutput%transptype)
          case (0)
             rhol = 1.0_fp
          case (1)
             rhol = cdryb(l)
          case (2)
             rhol = rhosol(l)
          end select
          do n = 1, nostat
             i        = i+1
             sbuff(i) = real(zsbv(n, l)/rhol,sp)
          enddo
       enddo
       ierror = putelt(fds, grnam5, 'ZSBV', uindex, 1, sbuff)
       if (ierror/= 0) goto 9999
       if (lsed > 0) then     
          !
          ! group 5: element 'ZSSU'
          !
          call sbuff_checksize(nostat*lsed)
          i = 0
          do l = 1, lsed
             select case(moroutput%transptype)
             case (0)
                rhol = 1.0_fp
             case (1)
                rhol = cdryb(l)
             case (2)
                rhol = rhosol(l)
             end select
             do n = 1, nostat
                i        = i+1
                sbuff(i) = real(zssu(n, l)/rhol,sp)
             enddo
          enddo
          ierror = putelt(fds, grnam5, 'ZSSU', uindex, 1, sbuff)
          if (ierror/= 0) goto 9999
          !
          ! group 5: element 'ZSSV'
          !
          call sbuff_checksize(nostat*lsed)
          i = 0
          do l = 1, lsed
             select case(moroutput%transptype)
             case (0)
                rhol = 1.0_fp
             case (1)
                rhol = cdryb(l)
             case (2)
                rhol = rhosol(l)
             end select
             do n = 1, nostat
                i        = i+1
                sbuff(i) = real(zssv(n, l)/rhol,sp)
             enddo
          enddo
          ierror = putelt(fds, grnam5, 'ZSSV', uindex, 1, sbuff)
          if (ierror/= 0) goto 9999
          !
          ! group 5: element 'ZRCA'
          !
          call sbuff_checksize(nostat*lsed)
          i = 0
          do l = 1, lsed
             do n = 1, nostat
                i        = i+1
                sbuff(i) = real(zrca(n, l),sp)
             enddo
          enddo
          ierror = putelt(fds, grnam5, 'ZRCA', uindex, 1, sbuff)
          if (ierror/= 0) goto 9999
       endif
    endif
    !
    ! his-sed-series: cross-sections
    !
    if (ntruv>0) then
       allocate (norig(ntruv), stat=istat)
       if (istat /= 0) then
          call prterr(lundia, 'U021', 'wrsedh: memory alloc error')
          call d3stop(1, gdp)
       endif
       do n = 1, ntruv
           norig( line_orig(n) ) = n
       enddo
       !
       !
       ! group 5: element 'SBTR'
       !
       call sbuff_checksize(ntruv*lsedtot)
       i = 0
       do l = 1, lsedtot
          select case(moroutput%transptype)
          case (0)
             rhol = 1.0_fp
          case (1)
             rhol = cdryb(l)
          case (2)
             rhol = rhosol(l)
          end select
          do n = 1, ntruv
             i        = i+1
             sbuff(i) = real(sbtr(norig(n), l)/rhol,sp)
          enddo
       enddo
       ierror = putelt(fds, grnam5, 'SBTR', uindex, 1, sbuff)
       if (ierror/= 0) goto 9999
       if (lsed > 0) then     
          !
          ! group 5: element 'SSTR'
          !
          call sbuff_checksize(ntruv*lsed)
          i = 0
          do l = 1, lsed
             select case(moroutput%transptype)
             case (0)
                rhol = 1.0_fp
             case (1)
                rhol = cdryb(l)
             case (2)
                rhol = rhosol(l)
             end select
             do n = 1, ntruv
                i        = i+1
                sbuff(i) = real(sstr(norig(n), l)/rhol,sp)
             enddo
          enddo
          ierror = putelt(fds, grnam5, 'SSTR', uindex, 1, sbuff)
          if (ierror/= 0) goto 9999
       endif
       !
       ! group 5: element 'SBTRC'
       !
       call sbuff_checksize(ntruv*lsedtot)
       i = 0
       do l = 1, lsedtot
          select case(moroutput%transptype)
          case (0)
             rhol = 1.0_fp
          case (1)
             rhol = cdryb(l)
          case (2)
             rhol = rhosol(l)
          end select
          do n = 1, ntruv
             i        = i+1
             sbuff(i) = real(sbtrc(norig(n), l)/rhol,sp)
          enddo
       enddo
       ierror = putelt(fds, grnam5, 'SBTRC', uindex, 1, sbuff)
       if (ierror/= 0) goto 9999
       if (lsed > 0) then     
          !
          ! group 5: element 'SSTRC'
          !
          call sbuff_checksize(ntruv*lsed)
          i = 0
          do l = 1, lsed
             select case(moroutput%transptype)
             case (0)
                rhol = 1.0_fp
             case (1)
                rhol = cdryb(l)
             case (2)
                rhol = rhosol(l)
             end select
             do n = 1, ntruv
                i        = i+1
                sbuff(i) = real(sstrc(norig(n), l)/rhol,sp)
             enddo
          enddo
          ierror = putelt(fds, grnam5, 'SSTRC', uindex, 1, sbuff)
          if (ierror/= 0) goto 9999
       endif
       deallocate (norig, stat=istat)
    endif
    !
    ierror = clsnef(fds)
    !
    ! write errormessage if error occurred and set error = .true.
    ! the files will be closed in clsnef (called in triend)
    !
 9999 continue
    if (ierror/= 0) then
       ierror = neferr(0, errmsg)
       call prterr(lundia, 'P004', errmsg)
       error = .true.
    endif
    deallocate(shlay_restr)
end subroutine wrsedh
