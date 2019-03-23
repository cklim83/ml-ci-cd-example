#!/usr/bin/env bash
# Reason for using /usr/bin/env bash instead of /bin/bash for shebang https://www.cyberciti.biz/tips/finding-bash-perl-python-portably-using-env.html

set -e # exit script if any evaluation exit status fails i.e. evaluates to 1

export PATH=$HOME/google-cloud-sdk/bin:$HOME/miniconda3/bin:$PATH # set path to google cloud and conda binaries so that subsequent commands can run
export virtual_environment_name="ml-ci-cd-example"
export REGION='us-central' # set to the same region where we're running Cloud ML Engine jobs
export PROJECT_ID="ml-ci-cd-example"
export BUCKET="gs://${PROJECT_ID}-mlengine"
export MODEL_NAME="nlp_sentiment"
export MINICONDA_REPO="https://repo.continuum.io/miniconda"

# Set correct miniconda download url, assume all using 64 bit system
# reference: https://stackoverflow.com/questions/394230/how-to-detect-the-os-from-a-bash-script
# reference: https://repo.continuum.io/miniconda/
if [[ "$OSTYPE" == "linux-gnu" ]]; then
  # Linux distribution
  installer_file="Miniconda3-4.5.12-Linux-x86_64.sh"
elif [[ "$OSTYPE" == "darwin"* ]]; then
  # Mac OSX, comes in form darwin[9.0|10.0] hence used wildcard match
  installer_file="Miniconda3-4.5.12-MacOSX-x86_64.sh"
elif [[ "$OSTYPE" == "msys" ]]; then
  # Lightweight shell and GNU utilities compiled for Windows (part of MinGW)
  installer_file="Miniconda3-4.5.12-Windows-x86_64.exe"
else
  echo "Unknown OSTYPE, exiting setup without installing..."
  exit 1
fi

# print download url for checking
miniconda_download_url="${MINICONDA_REPO}/${installer_file}"
echo "[INFO] Miniconda download path is $miniconda_download_url ..."

# Install miniconda bash installer if not yet exist
# Note: need a space for [[<space>"$OSTYPE... without it, will complains [[linux-gnu: command not found
if [[ "$OSTYPE" == "linux-gnu" || "$OSTYPE" == "darwin"* ]] && [[ ! -f "$HOME/miniconda3_installer/$installer_file" ]]; then
  mkdir -p $HOME/miniconda3_installer # -p will avoid exception if directory already exist.
  curl ${miniconda_download_url} -o "$HOME/miniconda3_installer/$installer_file"

  if [[ $? -eq 0 ]]; then # curl executed successfully
    echo "[INFO] $installer_file installed successfully at $HOME/miniconda3_installer/..."
  else
    echo "[ERROR] miniconda installer download failed. Exiting setup ..."
  fi

elif [[ "$OSTYPE" == "msys" ]] && [[ ! -f "%userprofile%\\miniconda3_installer\\$installer_file" ]]; then
  mkdir -p %UserProfile%\miniconda3_installer # -p will avoid exception if directory already exist.
  curl ${miniconda_download_url} -o "%UserProfile%\\miniconda3_installer\\$installer_file"

  if [[ $? -eq 0 ]]; then # curl executed successfully
    echo "[INFO] $installer_file installed successfully at %userprofile%\\miniconda3_installer..."
  else
    echo "[ERROR] miniconda installer download failed. Exiting setup ..."
  fi
fi

# Silent install of miniconda if conda binary does not exist at $HOME/miniconda3/bin
# Reference: https://docs.conda.io/projects/conda/en/latest/user-guide/install/macos.html#install-macos-silent
if [[ "$OSTYPE" == "linux-gnu" || "$OSTYPE" == "darwin"* ]] && [[ ! -f $HOME/miniconda3/bin/conda ]]; then
  bash $HOME/miniconda3_installer/$installer_file -b -p $HOME/miniconda3 # install using .sh script for linux/macOSX. TODO: What about for windows?
  if [[ $? -eq 0 ]]; then
    echo "[INFO] miniconda3 installed successfully at $HOME/miniconda3!"
    echo "[INFO] updating conda"
    conda update -n base conda -y #conda update conda will fail as it will check for native conda in PATH where prefix is different
  else
    echo "[ERROR] miniconda3 installed failed. Exiting setup ..."
  fi

elif [[ "$OSTYPE" == "msys" ]] && [[ ! -f %userprofile%\miniconda3\bin\conda ]]; then
  # silent execution of .exe
  # reference: https://docs.conda.io/projects/conda/en/latest/user-guide/install/windows.html
  start /wait "" %UserProfile%\miniconda3_installer\$installer_file /InstallationType=JustMe /RegisterPython=0 /S /D=%UserProfile%\miniconda3
  if [[ $? -eq 0 ]]; then
    echo "[INFO] miniconda3 installed successfully at %UserProfile%\\HOME\\miniconda3!"
    echo "[INFO] updating conda"
    conda update -n base conda -y #conda update conda will fail as it will check for native conda in PATH where prefix is different
  else
    echo "[ERROR] miniconda3 installed failed. Exiting setup ..."
  fi

else
  echo "[INFO] Conda found, updating conda ..."
  conda update -n base conda -y #conda update conda will fail as it will check for native conda in PATH where prefix is different
fi

if [[ "$OSTYPE" == "linux-gnu" || "$OSTYPE" == "darwin"* ]] && [[ ! -d "$HOME/miniconda3/envs/$virtual_environment_name" ]] ||
  [[ "$OSTYPE" == "msys" ]] && [[ ! -d "%UserProfile%\\miniconda3\\envs\\$virtual_environment_name" ]]; then
  echo "[INFO] Creating ${virtual_environment_name} virtual environment and installing dependencies..."
  conda env create -f ./ck_environment.yml # Needs conda path to already be in PATH, temporary achieved in this script with export statement above
fi

echo "[INFO] Done! 🚀 🚀 🚀"
echo "[INFO] To activate the virtual environment, run: source activate ${virtual_environment_name}"
echo "[INFO] To deactivate the virtual environment, run: source deactivate"
