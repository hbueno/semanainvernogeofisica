#!/bin/bash

set -x

# Model parameters
n1=150	o1=0 d1=0.020	
n2=460  o2=0 d2=0.020

# Data parameters
nw=7   ow=2.0  dw=2.             # frequency
ns=115 srcx0=1 srcdx=4 srcz=2    # shot
recz=2 recx0=1 recdx=1           # receiver

# Inversion parameters
niter=10     # number of iterations
sm=30       # smooth initial model

# Generate shot file for Helmholtz solver: sfhelm2D_genshot
sfhelm2D_genshot  n1=$n1 n2=$n2 ns=$ns d1=$d1 d2=$d2 \
    nw=$nw dw=$dw ow=$ow mag=1.0 nsource=1 dsource=1 \
    srcz=$srcz srcx0=$srcx0 srcdx=$srcdx | \
    sfput o1=0 o2=0 o3=1  > source-real.rsf

sfspike n1=$n1      d1=$d1 label1="Depth" unit1="km" \
        n2=$n2      d2=$d2 label2="Distance" unit2="km" \
        n3=$ns o3=1 d3=1   label3="Sources" unit3="Shot" \
        n4=$nw o4=$ow d4=$dw label4="Frequency" unit4="Hz" \
        mag=0.  > source-imag.rsf

< source-real.rsf sfcmplx source-imag.rsf  > source.rsf

# Generate receiver file for Helmholtz solver: sfhelm2D_genrec
sfhelm2D_genrec n1=$n1 n2=$n2 d1=$d1 d2=$d2 \
                recz=$recz recx0=$recx0 recdx=$recdx \
                > receiver.rsf

# 2D Helmholtz forward solver by LU factorization: sfhelm2D_forward
< marmvel.rsf sfhelm2D_forward source=source.rsf npml=10 verb=y > record.rsf

# 2D Frequency Domain Full Waveform Inversion: sfhelm2D_fwi
sfmath output="1./input" < marmvel.rsf | sfsmooth rect1=$sm rect2=$sm | \
    sfmath output="1./input" > marmini.rsf

../helm2D/sfhelm2D_fwi < marmini.rsf     \
    receiver=receiver.rsf source=source.rsf record=record.rsf dip= \
    niter=$niter uts=1 npml=10 precond=n radius= alpha0=0.01 > out.rsf

# View result
sfgrey < out.rsf gainpanel=a color=j bias=1.5 allpos=y pclip=100 scalebar=y | sfpen &
