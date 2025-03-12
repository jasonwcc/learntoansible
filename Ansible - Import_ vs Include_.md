```
Differences
import*
- statements are pre-processed at time playbooks are parsed
- expose all variables, templates to the remaining playbook
- slower performance if has large number of tasks
- has import_tasks, import_roles and import_playbook
- can use "when statement"
- can use "handlers"
- cannot use loop

include*
- statements are processed as they are read during playbook execution
- only expose variables, templates when called
- faster performance
- has include_tasks, include_roles
- can use "when statement"
- can use loop
- can use ansible-playbook --list-tasks and --start-at-task
- can use host or group inventory variables
- cannot use "handlers"
...
