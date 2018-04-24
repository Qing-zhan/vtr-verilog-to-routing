#!/bin/bash 
#1
trap ctrl_c INT

fail_count=0

function exit_program() {

    if [ -e regression_test/runs/failure.log ]
    then
	    line_count=$(wc -l < regression_test/runs/failure.log)
		fail_count=$[ fail_count+line_count ]
	fi
	
	if [ $fail_count -gt "0" ]
	then
		echo "Failed $fail_count"
		echo "View Failure log in ODIN_II/regression_test/runs/failure.log, "
	else
		echo "no run failure!"
	fi
	
	exit $fail_count
}

function ctrl_c() {

	echo ""
	echo "** EXITED FORCEFULLY **"
    fail_count=123456789
	exit_program 
}

function micro_test() {
	for benchmark in regression_test/benchmark/micro/*.v
	do 
		basename=${benchmark%.v}
		test_name=${basename##*/}
		input_vectors="$basename"_input
		output_vectors="$basename"_output	
		DIR="regression_test/runs/micro/$test_name" && mkdir -p $DIR
		
		cp $benchmark $DIR/circuit.v
		cp $input_vectors $DIR/circuit_input
		cp $output_vectors $DIR/circuit_output
		cp ../libs/libarchfpga/arch/sample_arch.xml $DIR/arch.xml
	done

	
	#verilog
	ls regression_test/runs/micro | xargs -n1 -P$1 -I test_dir /bin/bash -c \
	'./odin_II -E \
		-V regression_test/runs/micro/test_dir/circuit.v \
		-t regression_test/runs/micro/test_dir/circuit_input \
		-T regression_test/runs/micro/test_dir/circuit_output \
		-o regression_test/runs/micro/test_dir/tempa.blif \
		-sim_dir regression_test/runs/micro/test_dir/ \
		&> regression_test/runs/micro/test_dir/log \
	&& ./odin_II -E \
		-b regression_test/runs/micro/test_dir/tempa.blif \
		-t regression_test/runs/micro/test_dir/circuit_input \
		-T regression_test/runs/micro/test_dir/circuit_output \
		-sim_dir regression_test/runs/micro/test_dir/ \
		&> regression_test/runs/micro/test_dir/log \
	&& ./odin_II -E \
		-a regression_test/runs/micro/test_dir/arch.xml \
		-V regression_test/runs/micro/test_dir/circuit.v \
		-t regression_test/runs/micro/test_dir/circuit_input \
		-T regression_test/runs/micro/test_dir/circuit_output \
		-o regression_test/runs/micro/test_dir/tempb.blif \
		-sim_dir regression_test/runs/micro/test_dir/ \
		&> regression_test/runs/micro/test_dir/log \
	&& ./odin_II -E \
		-a regression_test/runs/micro/test_dir/arch.xml \
		-b regression_test/runs/micro/test_dir/tempb.blif \
		-t regression_test/runs/micro/test_dir/circuit_input \
		-T regression_test/runs/micro/test_dir/circuit_output \
		-sim_dir regression_test/runs/micro/test_dir/ \
		&> regression_test/runs/micro/test_dir/log \
	&& echo " --- PASSED == regression_test/runs/micro/test_dir" \
	|| (echo " -X- FAILED == regression_test/runs/micro/test_dir" \
		&& echo regression_test/runs/micro/test_dir >> regression_test/runs/failure.log )'

}

#1
#bench
function regression_test() {
	for benchmark in regression_test/benchmark/full/*.v
	do 
		basename=${benchmark%.v}
		test_name=${basename##*/}
		input_vectors="$basename"_input
		output_vectors="$basename"_output	
		DIR="regression_test/runs/full/$test_name" && mkdir -p $DIR
		
		cp $benchmark $DIR/circuit.v
		cp $input_vectors $DIR/circuit_input
		cp $output_vectors $DIR/circuit_output
	done

	
	ls regression_test/runs/full | xargs -P$1 -I test_dir /bin/bash -c \
		' ./odin_II -E -V regression_test/runs/full/test_dir/circuit.v \
			-t regression_test/runs/full/test_dir/circuit_input \
			-T regression_test/runs/full/test_dir/circuit_output \
			-o regression_test/runs/full/test_dir/temp.blif \
			-sim_dir regression_test/runs/full/test_dir/ \
				&> regression_test/runs/full/test_dir/log \
    	&& echo " --- PASSED == regression_test/runs/full/test_dir" \
    	|| (echo " -X- FAILED == regression_test/runs/full/test_dir" \
    		&& echo regression_test/runs/full/test_dir >> regression_test/runs/failure.log)'

}

#1				#2
#benchmark dir	N_trhead
function arch_test() {
	for benchmark in regression_test/benchmark/arch/*.v
	do 
    	basename=${benchmark%.v}
    	test_name=${basename##*/}
		DIR="regression_test/runs/arch/$test_name" && mkdir -p $DIR
		
		cp $benchmark $DIR/circuit.v
	done
	
	ls regression_test/runs/arch | xargs -P$1 -I test_dir /bin/bash -c \
		' ./odin_II -E -V regression_test/runs/arch/test_dir/circuit.v \
				-o regression_test/runs/arch/test_dir/temp.blif \
				-sim_dir regression_test/runs/arch/test_dir/ \
					&> regression_test/runs/arch/test_dir/log \
    	&& echo " --- PASSED == regression_test/runs/arch/test_dir" \
    	|| (echo " -X- FAILED == regression_test/runs/arch/test_dir" \
    		&& echo regression_test/runs/arch/test_dir >> regression_test/runs/failure.log)'
}

#1				#2
#benchmark dir	N_trhead
function syntax_test() {
	for benchmark in regression_test/benchmark/syntax/*.v
	do 
    	basename=${benchmark%.v}
    	test_name=${basename##*/}
		DIR="regression_test/runs/syntax/$test_name" && mkdir -p $DIR
		
		cp $benchmark $DIR/circuit.v
	done

	ls regression_test/runs/syntax | xargs -P$1 -I test_dir /bin/bash -c \
		' ./odin_II -E -V regression_test/runs/syntax/test_dir/circuit.v \
				-o regression_test/runs/syntax/test_dir/temp.blif \
				-sim_dir regression_test/runs/syntax/test_dir/ \
					&> regression_test/runs/syntax/test_dir/log \
    	&& echo " --- PASSED == regression_test/runs/syntax/test_dir" \
    	|| (echo " -X- FAILED == regression_test/runs/syntax/test_dir" \
    		&& echo regression_test/runs/syntax/test_dir >> regression_test/runs/failure.log)'
}


### starts here

#in MB
MIN_MEMORY_PER_PROC=4096
NB_OF_PROC=1

freeMEM=`free -mt | grep Total | awk '{print $4}'`
MAX_PROC=$[freeMEM/MIN_MEMORY_PER_PROC]

if [[ "$2" -gt "0" ]]
then
	NB_OF_PROC=$2
	MEM_PER_PROC=$[freeMEM/NB_OF_PROC]
	echo "Trying to run benchmark on $NB_OF_PROC processes with ~$MEM_PER_PROC MB per/proc (incl. swap)"
	
	if [[ "$NB_OF_PROC" -gt "$MAX_PROC" ]]
	then
		echo " $NB_OF_PROC would crash the system, we need a hard minimum of $MIN_MEMORY_PER_PROC MB per process"
		echo " Setting the number of process to $MAX_PROC"
		
		NB_OF_PROC=$MAX_PROC
	fi
fi


rm -Rf regression_test/runs/*
touch regression_test/runs/failure.log

START=$(date +%s%3N)

case $1 in

	"arch")
		arch_test $NB_OF_PROC 
		;;
	
	"syntax")
		syntax_test $NB_OF_PROC 
		;;
		
	"micro") 
		micro_test $NB_OF_PROC 
		;;
		
	"regression") 
		regression_test $NB_OF_PROC 
		;;
		
	"vtr_basic") 
		cd ..
		/usr/bin/perl run_reg_test.pl -j $NB_OF_PROC vtr_reg_basic
		cd ODIN_II
		;;
	
	"vtr_strong")
		cd ..
		/usr/bin/perl run_reg_test.pl -j $NB_OF_PROC vtr_reg_strong
		cd ODIN_II
		;;
		
	"pre_commit")  
		arch_test $NB_OF_PROC 
		syntax_test $NB_OF_PROC 
		micro_test $NB_OF_PROC 
		regression_test $NB_OF_PROC 
		cd ..
		/usr/bin/perl run_reg_test.pl -j $NB_OF_PROC vtr_reg_basic 
		/usr/bin/perl run_reg_test.pl -j $NB_OF_PROC vtr_reg_strong
		cd ODIN_II
		;;
		
	*) 
		echo 'nothing to run, ./verify_odin [ arch, syntax, micro, full, regression, vtr_basic, vtr_strong or pre_commit ] [ nb_of_process ]' 
		;;
esac

END=$(date +%s%3N)
echo "ran test in: $(( ((END-START)/1000)/60 )):$(( ((END-START)/1000)%60 )).$(( (END-START)%1000 )) [m:s.ms]"
exit_program
### end here


