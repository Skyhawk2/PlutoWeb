#!/bin/sh
#
# LamaBleu 04/2019
# Usage : mini_sna.sh Fstart Fend Step RXgain 
#       : ./mini_sna.sh 405000 460000 500 30
#       (frequencies in kHz)
#

rm -f /www/signal.csv 2>/dev/null

fstart=${1}*1000
fend=${2}*1000
step=${3}*1000
rxgain=$4

# TX : Pluto
echo "Applying hw settings..."
/usr/bin/iio_attr -a -q -c -o ad9361-phy voltage0 hardwaregain -20 1>/dev/null
/usr/bin/iio_attr -a -q -c -o ad9361-phy voltage0 sampling_frequency 1600000 1>/dev/null
/usr/bin/iio_attr -a -q -D ad9361-phy bist_prbs 0 1>/dev/null
/usr/bin/iio_attr -a -q -D ad9361-phy bist_tone "1 1 0 0" 1>/dev/null

echo "Starting scan..."
for freq in $(seq $((fstart)) $((step)) $((fend)))
 do

# TX : Pluto BIST MODE
fbist=$(($freq-100000))
/usr/bin/iio_attr -q -c ad9361-phy TX_LO frequency ${fbist} 1>/dev/null

# RX: get signal level
# -f 4 = sample rate. Increase up to 50 for a quicker sweep but less accurate.
pow_pluto -l $freq -g $rxgain -f 4 >> /www/signal.csv
#sleep 0.1
#tail -n 1 /www/signal.csv
done

# Pluto : stop bist mode
/usr/bin/iio_attr -D  9361-phy bist_tone "0 0 0 0" 2>/dev/null

echo "Scan complete.  Starting gnuplot..."

# Create plot
/bin/sh /pluto_power/plot.sh
