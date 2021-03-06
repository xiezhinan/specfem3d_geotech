! this subroutine applies displacement boundary conditions and determines
! global degrees of freedom
! REVISION
!   HNG, Jul 12,2011; ; HNG, Apr 09,2010
subroutine apply_bc(ismpi,myid,nproc,gdof,neq,errcode,errtag)
use global
implicit none
logical,intent(in) :: ismpi
integer,intent(in) :: myid,nproc
integer, dimension(nndof,nnode),intent(inout) :: gdof
integer,intent(out) :: neq
integer,intent(out) :: errcode
character(len=250),intent(out) :: errtag
integer :: i,ios,itmp,j,k
integer :: i1,i2,i3,i4,i5,i6,inod
integer :: ielmt,iface

character(len=20) :: format_str,ptail
character(len=250) :: fname
character(len=150) :: data_path

integer :: ipart ! partition ID

type faces
  integer,dimension(:),allocatable :: nod
end type faces
type (faces),dimension(8) :: face

errtag="ERROR: unknown!"
errcode=-1
! set data path
if(ismpi)then
  data_path=trim(part_path)
else
  data_path=trim(inp_path)
endif

ipart=myid-1 ! partition ID starts from 0
if(ismpi)then
  write(format_str,*)ceiling(log10(real(nproc)+1))
  format_str='(a,i'//trim(adjustl(format_str))//'.'//trim(adjustl(format_str))//')'
  write(ptail, fmt=format_str)'_proc',ipart
else
  ptail=""
endif

allocate(face(1)%nod(ngllx*ngllz),face(3)%nod(ngllx*ngllz))
allocate(face(2)%nod(nglly*ngllz),face(4)%nod(nglly*ngllz))
allocate(face(5)%nod(ngllx*nglly),face(6)%nod(ngllx*nglly))

! local node numbers for the faces (faces are numbered in exodus/CUBIT
! convention)
inod=0
i1=0; i2=0; i3=0; i4=0; i5=0; i6=0
do k=1,ngllz
  do j=1,nglly
    do i=1,ngllx
      inod=inod+1
      if (i==1)then
        ! face 4
        i4=i4+1
        face(4)%nod(i4)=inod
      endif
      if (i==ngllx)then
        ! face 2
        i2=i2+1
        face(2)%nod(i2)=inod
      endif
      if (j==1)then
        ! face 1
        i1=i1+1
        face(1)%nod(i1)=inod
      endif
      if (j==nglly)then
        ! face 3
        i3=i3+1
        face(3)%nod(i3)=inod
      endif
      if (k==1)then
        ! face 5
        i5=i5+1
        face(5)%nod(i5)=inod
      endif
      if (k==ngllz)then
        ! face 6
        i6=i6+1
        face(6)%nod(i6)=inod
      endif
    enddo
  enddo
enddo

!write(format_str,*)ceiling(log10(real(nproc)+1))
!format_str='(a,i'//trim(adjustl(format_str))//'.'//trim(adjustl(format_str))//')'

!write(fname, fmt=format_str)trim(inp_path)//trim(uxfile)//'_proc',ipart
fname=trim(data_path)//trim(uxfile)//trim(ptail)
!print*,fname
open(unit=11,file=trim(fname),status='old',action='read',iostat = ios)
if( ios /= 0 ) then
  write(errtag,*)'ERROR: file "'//trim(fname)//'" cannot be opened!'
  return
endif

!open(unit=11,file=trim(inp_path)//trim(uxfile),status='old',action='read',iostat=ios)
!if (ios /= 0)then
!  write(*,'(/,a)')'ERROR: input file "',trim(inp_path)//trim(uxfile),'" cannot be opened!'
!  stop
!endif
read(11,*)itmp
do
  read(11,*,iostat=ios)ielmt,iface ! This will read a line and proceed to next line
  if (ios/=0)exit
  gdof(1,g_num(face(iface)%nod,ielmt))=0
enddo
close(11)
!sync all
!call stop_all()

!write(fname, fmt=format_str)trim(inp_path)//trim(uyfile)//'_proc',ipart
fname=trim(data_path)//trim(uyfile)//trim(ptail)
!print*,fname
open(unit=11,file=trim(fname),status='old',action='read',iostat = ios)
if( ios /= 0 ) then
  write(errtag,*)'ERROR: file "'//trim(fname)//'" cannot be opened!'
  return
endif

!open(unit=11,file=trim(inp_path)//trim(uyfile),status='old',action='read',iostat=ios)
!if (ios /= 0)then
!  write(*,'(/,a)')'ERROR: input file "',trim(inp_path)//trim(uyfile),'" cannot be opened!'
!  stop
!endif
read(11,*)itmp
do
  read(11,*,iostat=ios)ielmt,iface ! This will read a line and proceed to next line
  if (ios/=0)exit
  gdof(2,g_num(face(iface)%nod,ielmt))=0
enddo
close(11)

!write(fname, fmt=format_str)trim(inp_path)//trim(uzfile)//'_proc',ipart
fname=trim(data_path)//trim(uzfile)//trim(ptail)
!print*,fname
open(unit=11,file=trim(fname),status='old',action='read',iostat = ios)
if( ios /= 0 ) then
  write(errtag,*)'ERROR: file "'//trim(fname)//'" cannot be opened!'
  return
endif

!open(unit=11,file=trim(inp_path)//trim(uzfile),status='old',action='read',iostat=ios)
!if (ios /= 0)then
!  write(*,'(/,a)')'ERROR: input file "',trim(inp_path)//trim(uzfile),'" cannot be opened!'
!  stop
!endif
!if(myid==1) print*,'file:',fname
read(11,*)itmp
!if(myid==1) print*,itmp
do
  read(11,*,iostat=ios)ielmt,iface ! This will read a line and proceed to next line
  if (ios/=0)exit
  gdof(3,g_num(face(iface)%nod,ielmt))=0
enddo
close(11)
!sync all
!error stop

! compute modified gdof
neq=0
do j=1,ubound(gdof,2)
  do i=1,ubound(gdof,1)
    if(gdof(i,j)/=0)then
      neq=neq+1
      gdof(i,j)=neq
    endif
  enddo
enddo

! compute nodal to global
errcode=0
return

end subroutine apply_bc

