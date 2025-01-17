*Note the code examples might not be 100% correct

I would recommend setting the current working directory to the ./python_projects folder

code --> cd shared/boston_zoning/working_paper/python_programs


To set up the boston_zoning python environment and have it be that is available on JupyterHub 
you will need to try one of the following. I would recommend specifying the prefix for the 
environment to your own user folder and not the ./shared/venv/ folder which makes them
accessible by anyone. Replace FED ID with you login id (ie. a1nfc04).

	code --> conda create --prefix /home/<FED ID>/.conda/envs/boston_zoning --file boston_zoning_env.txt


To activate the environment in the terminal

	code --> conda activate boston_zoning


To install any needed packages you SHOULD DO THIS IN THE TERMINAL ONLY

	code --> conda instal <package name>

- USE: conda install <pkg name>, this should install the default channel	

- AVOID: conda-force <pkg name>

- if no defualt is available use 'conda install conda-forge::<pkg name>', this tries to pull as many default packages as possible 


To make the environment available on JupyterHub...

- open the terminal 

- activate the environment 

- enter the following: python -m ipykernel install --name <env name> --display-name <env display name> --user

You can list the kernels you have on jupyter hub
	code --> jupyter kernelspec list
		
To removal an environment kernel 
	jupyter kernelspec remove <env name>