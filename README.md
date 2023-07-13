
# Wordpress Site hosted on LEMP stack using docker-compose and bash script

As asked by I have created a bash script called wordpress_docker.sh in the file.


## Steps followed 
The content inside the script follows series of action mentioned below:

    1. Checks whether the docker is present or not. 
    2. Installs docker if not present.
    3. Checks whether the docker-compose is present or not in the machine.
    4. Installs Docker-compose if not present.
    5. Checks if the argument is passed for setting up host site. 
    6. Takes the first argument and makes it a name of site.
    7. Creates a directory to store nginx configurations
    8. Stores the configurations to the respected files 
    9. Create a docker-compose.yaml file for all the services to be managed for creating LEMP stack
    10. The function en_dis_site starts or stops the site on demand
    11. The function delete will remove all traces of site 
    12. The function open is used to launch webapplication over browser

## Commands
first of all we need to clone the repo
    
     git clone rtcamp-assignment

provide executable permission to wordpress_docker.sh

    chmod +x wordpress_docker.sh

In order to enable or start 
    
    ./wordpress_docker.sh example.com start

To stop the current site

    ./wordpress_docker.sh example.com stop

To open and view the website 

    ./wordpress_docker.sh example.com open

To delete the site
    
    ./wordpress_docker.sh example.com delete

### Note: 
Files and directories other than "wordpress_docker.sh" and "Readme.md" in the repository is just to show the available outcomes and an optional view for a test and can be deleted while testing in local 
