# coding: utf-8
# Run as: luigid & PYTHONPATH='.' python politica_preventiva.py
# RunPipelines --workers 3

import os
import datetime
import logging
import boto3
import luigi
import luigi.s3
import multiprocessing
from dotenv import load_dotenv
from os.path import join, dirname
from luigi.s3 import S3Target, S3Client
from luigi import configuration
from joblib import Parallel, delayed
from itertools import product
from dotenv import load_dotenv,find_dotenv

from ingest.ingest_orchestra import UpdateOutput, LocalToS3
from etl.etl_orchestra import ETL
from utils.pipeline_utils import parse_cfg_list, extra_parameters
import pdb


# Variables de ambiente
load_dotenv(find_dotenv())

# AWS
aws_access_key_id = os.environ.get('AWS_ACCESS_KEY_ID')
aws_secret_access_key = os.environ.get('AWS_SECRET_ACCESS_KEY')

class RunPipelines(luigi.WrapperTask):

    """ 
        Master Wrapper de Compranet Pipeline.

    """

    today = datetime.date.today()
    year_month = str(today.year) + "-"+ str(today.month)
    year_month_day = year_month + "-" + str(today.day)

    def requires(self):

        yield IngestPipeline(self.year_month)
        #yield EtlPipeline(self.year_month)
        #yield ModelPipeline(self.year_month)


class IngestPipeline(luigi.WrapperTask):

    """
        Este wrapper ejecuta la ingesta de cada pipeline-task

    Input Args (From luigi.cfg):
        pipelines: lista con los pipeline-tasks especificados a correr.

    """

    year_month = luigi.Parameter()
    conf = configuration.get_config()
    pipelines = parse_cfg_list(conf.get("IngestPipeline", "pipelines"))
    #python_pipelines = parse_cfg_list(conf.get("IngestPipeline", "python_pipelines"))

    def requires(self):

        for pipeline_task in self.pipelines:

            yield UpdateDB(pipeline_task=pipeline_task, year_month=self.year_month)




# class EtlPipeline(luigi.WrapperTask):
#     """
#         Este wrapper ejecuta el ETL de cada pipeline-task
#         Input - lista con los pipeline-tasks especificados a correr.
#     """

#     year_month = luigi.Parameter()

#     def requires(self):

#         yield IngestPipeline(self.year_month) 

#     def run(self):
#         yield ETL(year_month=self.year_month)


# class ModelPipeline(luigi.WrapperTask):

#     """
#         Este wrapper ejecuta el código de Modelos
#     """

#     year_month = luigi.Parameter()
#     conf = configuration.get_config()

#     def requires(self):

#         yield ETL(year_month=self.year_month)

#     def run(self):

#         yield Model(year_month=self.year_month)






if __name__ == "__main__":

    luigi.run()