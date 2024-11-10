#Cloning repo to linix 

#!/bin/bash 
 
echo "Enter the repository :"

read repolink

getrepo(){
  echo "getting repository please wait."
  git clone repolink
}

getrepo