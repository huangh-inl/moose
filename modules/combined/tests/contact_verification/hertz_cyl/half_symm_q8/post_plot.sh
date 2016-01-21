#!/bin/bash

NO_ARGS=1

# Flag to keep generated files
keep="no"

usage ()
{
    echo "Usage `basename $0` options (-hk)"
    echo "       -h This help"
    echo "       -k keep generated files"
    exit
}

# Process commandline arguments, if any
if [ $# -ge "$NO_ARGS" ]
then
  while getopts ":hk" Option
  do
    case $Option in
	h ) usage;;
	k ) keep="yes";;
    esac
  done
fi

# Function to cleanup generated files
cleanup ()
{
    rm -f *.dat *.xmgr *.met *.plt *.log gold/*.dat gold/*.xmgr gold/*.met
}

# Gnuplot formatting for specific plots to be generated
gnuplot_header="set terminal postscript enhanced color"
title[0]="Displacement Plot"
title[1]="Iteration Plot"
title[2]="Reaction Plot"
# Note title[3] specified below in main loop
title[4]="Contact Shear Plot"
title[5]="Tangential Traction Plot"

ylabel[0]="Displacement"
ylabel[1]="Iterations"
ylabel[2]="Reaction"
ylabel[3]="Pressure"
ylabel[4]="Interfacial Shear"
ylabel[5]="Traction"

xlabel="Time"
xlabel2="Distance"
xlabel4="Lateral Displacement"

# Gnuplot line formatting, curr output and gold output
afmt="w l lt 1 lw 3 lc 0"
cfmt="w lp lt 2 pt 2 lc 3"
gfmt="w lp lt 1 pt 4 lc 2"
cpnt="w p pt 2 lc 3"
gpnt="w p pt 4 lc 2"

# Select CSV files generated for plotting
csv_files="*out.csv"

# Main loop for processing files
for file in $csv_files
do
    echo "Generating plot files for ${file}"
    base=${file/%\.csv/}
    datfile="${base}.dat"
    datfile2="${base}2_splot.xmgr"
    datfile3="${base}2_xyplot.xmgr"
    datfile4="${base}2_tang.xmgr"
    pltfile="${base}.plt"
    logfile="${base}.log"
    psfile="${base}.ps"

# Create data files for Gnuplot from CSV files
    perl -ple 's/^time/# time/' ${file} > ${datfile}
    perl -i -ple 's/,/ /g' ${datfile}
    if [ -d "gold" ]
    then
      perl -ple 's/^time/# time/' gold/${file} > gold/${datfile}
      perl -i -ple 's/,/ /g' gold/${datfile}
    fi

    top_react_y=`perl -ne 'if(/^1 .* (.*)$/){print "$1";}' ${file}`
    title[3]="Contact Pressure Plot (Time = 1.0, P = $top_react_y)"

# Generate interface pressure data using BLOT
    algebra ${base}.e ${base}2.e < algebra.inp > ${logfile} 2>&1
    blot --device met --input blot_splot.inp --basename ${base}2_splot ${base}2.e >> ${logfile} 2>&1
    blot --device met --input blot_xyplot.inp --basename ${base}2_xyplot ${base}2.e >> ${logfile} 2>&1
    blot --device met --input blot_tang_tract.inp --basename ${base}2_tang ${base}2.e >> ${logfile} 2>&1
    cd gold
    algebra ${base}.e ${base}2.e < ../algebra.inp >> ../${logfile} 2>&1
    blot --device met --input ../blot_splot.inp --basename ${base}2_splot ${base}2.e >> ../${logfile} 2>&1
    blot --device met --input ../blot_xyplot.inp --basename ${base}2_xyplot ${base}2.e >> ../${logfile} 2>&1
    blot --device met --input ../blot_tang_tract.inp --basename ${base}2_tang ${base}2.e >> ../${logfile} 2>&1
    perl -i -ple 's/^@/#@/g' ${datfile2}
    perl -i -ple 's/^&/#&/g' ${datfile2}
    perl -0777 -i -pe 's/ (0\.00)/#$1/' ${datfile2}
    perl -i -ple 'if(/ s1 /){$done=1}else{unless($done){s/^ /-/}}' ${datfile2}
    perl -i -ple 's/^@/#@/g' ${datfile3}
    perl -i -ple 's/^&/#&/g' ${datfile3}
    perl -i -ple 's/^@/#@/g' ${datfile4}
    perl -i -ple 's/^&/#&/g' ${datfile4}
    cd ..
    perl -i -ple 's/^@/#@/g' ${datfile2}
    perl -i -ple 's/^&/#&/g' ${datfile2}
    perl -0777 -i -pe 's/ (0\.00)/#$1/' ${datfile2}
    perl -i -ple 'if(/ s1 /){$done=1}else{unless($done){s/^ /-/}}' ${datfile2}
    perl -i -ple 's/^@/#@/g' ${datfile3}
    perl -i -ple 's/^&/#&/g' ${datfile3}
    perl -i -ple 's/^@/#@/g' ${datfile4}
    perl -i -ple 's/^&/#&/g' ${datfile4}
 
# Check for already existing plot files
    if [ -e ${pltfile} ]
    then
	echo "${pltfile} already exists!"
	echo "Remove *.plt files by hand."
	exit
    fi

# Create plot files for Gnuplot
    echo "$gnuplot_header" > ${pltfile}
    echo "set output \"${psfile}\"" >> ${pltfile}
    echo "set title \"${title[0]}\"" >> ${pltfile}
    echo "set output \"${psfile}\"" >> ${pltfile}
    echo "set xlabel \"$xlabel\"" >> ${pltfile}
    echo "set ylabel \"${ylabel[0]}\"" >> ${pltfile}
    echo "plot \"${datfile}\" using 1:5 t \"Node 639 (x-disp,curr)\" $cfmt,\\" >> ${pltfile}
    echo "\"gold/${datfile}\" using 1:5 t \"Node 639 (x-disp,gold)\" $gfmt" >> ${pltfile}
    echo "plot \"${datfile}\" using 1:6 t \"Node 639 (y-disp,curr)\" $cfmt,\\" >> ${pltfile}
    echo "\"gold/${datfile}\" using 1:6 t \"Node 639 (y-disp,gold)\" $gfmt" >> ${pltfile}
    echo "set title \"${title[1]}\"" >> ${pltfile}
    echo "set xlabel \"$xlabel\"" >> ${pltfile}
    echo "set ylabel \"${ylabel[1]}\"" >> ${pltfile}
    echo "plot \"${datfile}\" using 1:7 t \"Lin It (curr)\" $cfmt,\\" >> ${pltfile}
    echo "\"${datfile}\" using 1:8 t \"NonLin It (curr)\" $cfmt,\\" >> ${pltfile}
    echo "\"gold/${datfile}\" using 1:7 t \"Lin It (gold)\" $gfmt,\\" >> ${pltfile}
    echo "\"gold/${datfile}\" using 1:8 t \"NonLin It (gold)\" $gfmt" >> ${pltfile}
    echo "set title \"${title[2]}\"" >> ${pltfile}
    echo "set xlabel \"$xlabel\"" >> ${pltfile}
    echo "set ylabel \"${ylabel[2]}\"" >> ${pltfile}
    echo "plot \"${datfile}\" using 1:3 t \"Bot React X (curr)\" $cfmt,\\" >> ${pltfile}
    echo "\"gold/${datfile}\" using 1:3 t \"Bot React X (gold)\" $gfmt" >> ${pltfile}
    echo "plot \"${datfile}\" using 1:4 t \"Bot React Y (curr)\" $cfmt,\\" >> ${pltfile}
    echo "\"gold/${datfile}\" using 1:4 t \"Bot React Y (gold)\" $gfmt" >> ${pltfile}
    echo "plot \"${datfile}\" using 1:11 t \"Top React X (curr)\" $cfmt,\\" >> ${pltfile}
    echo "\"gold/${datfile}\" using 1:11 t \"Top React X (gold)\" $gfmt" >> ${pltfile}
    echo "plot \"${datfile}\" using 1:12 t \"Top React Y (curr)\" $cfmt,\\" >> ${pltfile}
    echo "\"gold/${datfile}\" using 1:12 t \"Top React Y (gold)\" $gfmt" >> ${pltfile}
    echo "set title \"${title[3]}\"" >> ${pltfile}
    echo "set xlabel \"$xlabel2\"" >> ${pltfile}
    echo "set ylabel \"${ylabel[3]}\"" >> ${pltfile}
    echo "P = abs( $top_react_y )" >> ${pltfile}
    echo "R_star = 3./2." >> ${pltfile}
    echo "E_star = 5.4945E5" >> ${pltfile}
    echo "a = sqrt((4. * P * R_star)/(pi * E_star))" >> ${pltfile}
    echo "set xrange [0:0.2]" >> ${pltfile}
    echo "set samples 3000" >> ${pltfile}
    echo "f(x) = (2. * P)/(pi * a**2) * sqrt(a**2 - x**2)" >> ${pltfile}
    echo "plot [t=-1.5*a:1.5*a] f(t) t \"Hertz Analytical Solution (frictionless)\" $afmt,\\" >> ${pltfile}
    echo "\"${datfile2}\" using 1:2 t \"Contact Pressure (curr)\" $cpnt,\\" >> ${pltfile}
    echo "\"gold/${datfile2}\" using 1:2 t \"Contact Pressure (gold)\" $gpnt" >> ${pltfile}
    echo "set title \"${title[4]}\"" >> ${pltfile}
    echo "set xlabel \"$xlabel4\"" >> ${pltfile}
    echo "set ylabel \"${ylabel[4]}\"" >> ${pltfile}
    echo "set xrange [*:*]" >> ${pltfile}
    echo "plot \"${datfile3}\" using 1:2 t \"Top React X (curr)\" $cfmt,\\" >> ${pltfile}
    echo "\"gold/${datfile3}\" using 1:2 t \"Top React X (gold)\" $gfmt" >> ${pltfile}
    echo "set title \"${title[5]}\"" >> ${pltfile}
    echo "set xlabel \"$xlabel2\"" >> ${pltfile}
    echo "set ylabel \"${ylabel[5]}\"" >> ${pltfile}
    echo "plot \"${datfile4}\" using 1:2 t \"Tangential Traction X (curr)\" $cfmt,\\" >> ${pltfile}
    echo "\"gold/${datfile4}\" using 1:2 t \"Tangential Traction X (gold)\" $gfmt" >> ${pltfile}

# Execute Gnuplot on generated file
    gnuplot < ${pltfile} >> ${logfile} 2>&1
done

# Cleanup files
if [ "$keep" != "yes" ]
then
    cleanup
fi

exit 0
