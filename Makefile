########################################
# Makefile for pipeline
# Version 0.1
# Roberto Sánchez 
# Tomado de Adolfo De Unánue
# 11 de marzo de 2017
########################################

.PHONY: clean data lint init deps sync_to_s3 sync_from_s3

########################################
##            Variables               ##
########################################

PROJECT_NAME:=$(shell cat .project-name)
PROJECT_VERSION:=$(shell cat .project-version)
PROJECT_USER:=$(shell cat .project-user)


## Versión de python
VERSION_PYTHON:=$(shell cat .python-version)

HELL := /bin/bash

########################################
##            Ayuda                   ##
########################################

help:   ##@ayuda Diálogo de ayuda
	@perl -e '$(HELP_FUN)' $(MAKEFILE_LIST)


########################################
##      Tareas de Ambiente            ##
########################################

init: prepare ##@dependencias Prepara la computadora para el funcionamiento del proyecto
	$(source ./infraestructura/.env)

prepare: deps 
#	pyenv virtualenv ${PROJECT_NAME}_venv
#	pyenv local ${PROJECT_NAME}_venv

#pyenv: .python-version
#	@pyenv install $(VERSION_PYTHON)

deps: pip pip-dev

pip: requirements.txt
	@sudo pip install -r $<

pip-dev: requirements-dev.txt
	@sudo pip install -r $<

info:
	@echo Proyecto: $(PROJECT_NAME) ver. $(PROJECT_VERSION)
	@python --version
	@pyenv --version
	@pip --version

########################################
##      Tareas de Limpieza            ##
########################################

clean: ##@limpieza Elimina los archivos no necesarios
	@find . -name "__pycache__" -exec rm -rf {} \;
	@find . -name "*.egg-info" -exec rm -rf {} \;
	@find . -name "*.pyc" -exec rm {} \;
	@find . -name '*.pyo' -exec rm -f {} \;
	@find . -name '*~' ! -name '*.un~' -exec rm -f {} \;

clean_venv: ##@limpieza Destruye la carpeta de virtualenv
	@pyenv uninstall -f ${PROJECT_NAME}_venv
	echo ${VERSION_PYTHON} > .python-version

########################################
##      Tareas de Validación          ##
########################################

lint:  ##@test Verifica que el código este bien escrito (según PEP8)
	@flake8 --exclude=lib/,bin/,docs/conf.py .

tox: clean  ##@test Ejecuta tox
	tox

####################################
##      Tareas del Proyecto           ##
########################################

run:       ##@proyecto Ejecuta el pipeline de datos
	$(MAKE) --directory=$(PROJECT_NAME) run

setup: build install ##@proyecto Crea las imágenes del pipeline e instala el pipeline como paquete en el PYTHONPATH

remove: uninstall  ##@proyecto Destruye la imágenes del pipeline y desinstala el pipeline del PYTHONPATH
	$(MAKE) --directory=$(PROJECT_NAME) clean


build:
	$(MAKE) --directory=$(PROJECT_NAME) build

install:
	@pip install --editable .

uninstall:
	@while pip uninstall -y ${PROJECT_NAME}; do true; done
	@python setup.py clean


########################################
##            Funciones               ##
##           de soporte               ##
########################################

## NOTE: Tomado de https://gist.github.com/prwhite/8168133 , en particular,
## del comentario del usuario @nowox, lordnynex y @HarasimowiczKamil

## COLORS
BOLD   := $(shell tput -Txterm bold)
GREEN  := $(shell tput -Txterm setaf 2)
WHITE  := $(shell tput -Txterm setaf 7)
YELLOW := $(shell tput -Txterm setaf 3)
RED    := $(shell tput -Txterm setaf 1)
BLUE   := $(shell tput -Txterm setaf 5)
RESET  := $(shell tput -Txterm sgr0)

## NOTE: Las categorías de ayuda se definen con ##@categoria
HELP_FUN = \
    %help; \
    while(<>) { push @{$$help{$$2 // 'options'}}, [$$1, $$3] if /^([a-z0-9_\-]+)\s*:.*\#\#(?:@([a-z0-9_\-]+))?\s(.*)$$/ }; \
    print "uso: make [target]\n\n"; \
    for (sort keys %help) { \
    print "${BOLD}${WHITE}$$_:${RESET}\n"; \
    for (@{$$help{$$_}}) { \
    $$sep = " " x (32 - length $$_->[0]); \
    print "  ${BOLD}${BLUE}$$_->[0]${RESET}$$sep${GREEN}$$_->[1]${RESET}\n"; \
    }; \
    print "\n"; }

## Verificando dependencias
## Basado en código de Fernando Cisneros @ datank

EXECUTABLES = docker docker-compose docker-machine pyenv ag pip hub
TEST_EXEC := $(foreach exec,$(EXECUTABLES),\
				$(if $(shell which $(exec)), some string, $(error "${BOLD}${RED}ERROR${RESET}: No está $(exec) en el PATH, considera revisar Google para instalarlo (Quizá 'apt-get install $(exec)' funcione...)")))

ifeq (,$(wildcard .project-name))
    $(error ${BOLD}${RED}ERROR${RESET}: El archivo .project-name debe de existir. Debes de crear un archivo .project-name, el cual debe de contener el nombre del proyecto, (e.g dragonfly))
endif

ifndef PROJECT_NAME
	  $(error ${BOLD}${RED}ERROR${RESET}: El archivo .project-name existe pero está vacío. Debe de contener el nombre del proyecto (e.g. ghostbuster))
endif

ifeq ($(PROJECT_NAME), dummy)
   $(error ${BOLD}${RED}ERROR${RESET}: El nombre del proyecto no puede ser 'dummy', por favor utiliza otro nombre (actualmente: $(PROJECT_NAME)))
endif

