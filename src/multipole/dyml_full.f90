! calculates the entire list of angular components of the spherical harmonics
! for all l in [0, l_max] and valid m in [-l, l]. therefore, the values are
! stored in an array of complex numbers of length (l+1)^2. verifying the values 
! against the scipy libraries and against other implementations in this source
! show rather large errors (~5%) for negative m values of large l, but only for
! some angle ranges. this may be due to the use of single-precision values which
! cannot handle the high recursion values of factorials. for this reason values
! of l_max higher than 10 are not recommended.
!
!   arguments (in) ------------------------------------------------------------
!     l_max : INTEGER
!       the highest degree of the polynomial to calculate to. it must be
!       non-negative, [0,inf), for providing values to the infinite series of
!       spherical harmonics
!     theta : REAL
!       the polar angle (colatitude), should be in range [0, pi]
!     phi : REAL
!       the azimuthal angle, should be in range [0, 2*pi]
!
!   arguments (out) -----------------------------------------------------------
!     yml_vals : COMPLEX, DIMENSION((l_max+1)**2)
!       the value of the angular component, both real and complex parts
!     dyml_dtheta : COMPLEX, DIMENSION((l_max+1)**2)
!       the values of the derivatives of the angular components with respect to
!       the polar angle, theta
!     dyml_dphi : COMPLEX, DIMENSION((l_max+1)**2)
!       the values of the derivatives of the angular compoenets with respect to
!       the azimuthal angle, phi
!
!   notes ---------------------------------------------------------------------
!     i'm so sorry about the angular variable naming. the papers i reference are
!     all written by physicists not mathematicians, and it's just easier to keep
!     their notation...
SUBROUTINE dyml_full(l_max,theta,phi,yml_vals,dyml_dtheta,dyml_dphi)
    INTEGER, INTENT(IN) :: l_max
    REAL, INTENT(IN) :: theta, phi
    COMPLEX, DIMENSION((l_max+1)**2), INTENT(OUT) :: yml_vals
    COMPLEX, DIMENSION((l_max+1)**2), INTENT(OUT) :: dyml_dtheta
    COMPLEX, DIMENSION((l_max+1)**2), INTENT(OUT) :: dyml_dphi

    ! define the parameters, j = sqrt(-1) (i like saving 'i' for indices)
    COMPLEX, PARAMETER :: j = (0,1.0)
    REAL, PARAMETER :: PI_FACTOR = 1.0 / (16.0 * ATAN(1.0))

    ! local variables for intermediate calculations
    REAL, DIMENSION((l_max+1)**2) :: pml, dpml
    REAL :: temp, prefactor

    ! for l of 0, the yml_vals is simply 1.0
    IF (l == 0) RETURN

    ! make sure to clear all the values
    yml_vals = (1.0,0.0)
    dyml_dtheta = (1.0,0.0)
    dyml_dphi = (0.0,0.0)

    ! apply the normalization factor for the l = 0, m = 0 value
    yml_vals(1) = SQRT(PI_FACTOR)

    ! calculate the phi components
    i = 1
    DO l = 1, l_max
        ! increment the index to point to the next m = 0
        i = i + (2 * l)

        ! set the common l-dependent prefactor
        prefactor = SQRT((2 * l + 1) * PI_FACTOR)
        yml_vals(i) = prefactor

        ! reset the temporary value for the m-dependent prefactor
        temp = 1.0
        DO m = 1, l
            ! performing the square root here prevents NaN with REAL variables
            temp = temp * SQRT((l + m) * (l - m + 1.0))

            ! apply the prefactor of sqrt((l-m)!/(l+m)!)
            yml_vals(i - m) = prefactor * temp
            yml_vals(i + m) = prefactor / temp

            ! apply the phi-component
            yml_vals(i - m) = yml_vals(i - m) * EXP(-j * m * phi)
            yml_vals(i + m) = yml_vals(i + m) * EXP( j * m * phi)

            ! apply the phi-component derivative
            dyml_dphi(i - m) = -j * m
            dyml_dphi(i + m) =  j * m
        END DO
    END DO

    ! calculate the theta component (associated Legendre of cos(theta))
    call dpmlcos_full(l_max,theta,pml,dpml)

    ! since these are partial derivatives some values are reused
    dyml_dtheta = yml_vals * dpml       ! derivative w.r.t. theta depends on Pml
    yml_vals = yml_vals * pml           ! calculate the Yml values
    dyml_dphi = dyml_dphi * yml_vals    ! d/dphi is a multiple of Yml

END SUBROUTINE dyml_full