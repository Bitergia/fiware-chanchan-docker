from fabric.api import task
from fabric.tasks import Task
from conf import settings
from fabric.context_managers import lcd
from fabric.operations import local as lrun

@task
def sync(horizon_path=settings.HORIZON_ROOT):
    with lcd(horizon_path):
        lrun(('sudo tools/with_venv.sh python access_control_xacml.py '))