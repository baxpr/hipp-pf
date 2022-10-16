#!/usr/bin/env bash
#
# Main entrypoint for HPF pipeline.

# Initialize defaults for any input parameters where that seems useful
export t1_niigz=/INPUTS/t1.nii.gz
export fs_subjdir=/INPUTS/SUBJECT
export out_dir=/OUTPUTS
export pthresh=50

# Parse input options
while [[ $# -gt 0 ]]; do
    key="$1"
    case $key in      
        --t1_niigz)        export t1_niigz="$2";        shift; shift ;;
        --fs_subjdir)      export fs_subjdir="$2";      shift; shift ;;
        --pthresh)         export pthresh="$2";         shift; shift ;;
        --out_dir)         export out_dir="$2";         shift; shift ;;
        *) echo "Input ${1} not recognized"; shift ;;
    esac
done

cd "${out_dir}"

prepfiles.sh

registrations.sh

transforms.sh

compute_hpf.sh

make_pdf.sh

organize_outputs.sh
