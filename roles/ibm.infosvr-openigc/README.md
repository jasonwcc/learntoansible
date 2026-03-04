# ansible-role-infosvr-openigc

Ansible role for automating the deployment of OpenIGC objects for the Information Governance Catalog, within IBM Information Server.

New to Ansible? This [simple introduction](https://cmgrote.github.io/ansible-tutorial/) might help.

## Requirements

- Ansible v2.6.x
- The following utilities pre-installed on your control machine:
  - zip
  - curl

The role does not use any privilege escalation, and executes primarily on the control machine itself (only pushing generate files directly against the relevant APIs in the environment).

Because of the role's use of advanced Jinja templating for the YAML-based inputs, a version of Ansible with a recent Jinja distribution is required (v2.4 is not adequate, hence bump to requiring v2.6.x). While v2.7 now includes the ability for the `uri` module to submit files, it does not provide any capability to override the certificate authority -- so to allow validation of self-signed certificates, without needing to modify the CA of the control machine itself, we still rely on `curl` for the time being.

## Role Variables

See `defaults/main.yml` for inline documentation, and the example below for the main variables needed.

This role will attempt to automatically re-use variables from the [IBM.infosvr](https://galaxy.ansible.com/IBM/infosvr) role, for instance by using a playbook that first imports `IBM.infosvr` using `tasks_from=setup_vars.yml`.

By default, the role will do SSL verification of self-signed certificates if you have retrieved them using `IBM.infosvr`'s `get_certificate.yml` task (see example playbook below). This is controlled by the `ibm_infosvr_openigc_verify_selfsigned_ssl` variable of the role: if you want to only verify against properly signed and trusted SSL certificates, you can set this variable to `False` and any self-signed domain tier certificate will no longer be trusted.

## Example Playbook

The role is primarily inteded to be imported into other playbooks as-needed for the deployment of OpenIGC objects -- both bundles and asset instances. (Thus the need for Ansible v2.4.x and the `import_role` module.)

```yml
---
- name: setup Information Server vars
  hosts: all
  tasks:
    - import_role: name=IBM.infosvr tasks_from=setup_vars.yml
    - import_role: name=IBM.infosvr tasks_from=get_certificate.yml

- name: load OpenIGC bundles and assets
  hosts: ibm_information_server_engine
  roles:
    - IBM.infosvr-openigc
  vars:
    bundles:
      - /some/directory/<BundleId>
    assets_as_xml:
      - /some/directory/asset_instances-<BundleId>.xml
    assets_as_yaml:
      - /some/directory/assets.yml
    flows_as_xml:
      - /some/directory/lineage_flows-<BundleId>.xml
    flows_as_yaml:
      - /some/directory/lineage.yml
```

## Action (and object) structures

The following describes all of the actions and object types currently covered by this role, and their expected structures. Regardless of the order in which the variables are listed in the playbook, they will be loaded in the order they are listed below.

### `bundles`

The list of directories provided through this variable should be in bundle form, specifically containing the following structure:

- `<BundleId>`: the root directory you point to should have the same case-sensitive name as the bundle itself
  - `asset_type_descriptor.xml`: the XML that describes the bundle (ie. all the classes, their relationships / containment, etc)
  - `i18n`: a directory containing labels
    - `labels.properties`: the translate-able set of class and attribute labels
  - `icons`: a directory containing two `.gif` files per class defined by the bundle:
    - `<ClassId>-icon.gif`: should be a 16x16 pixel representation of the class, and could also be a `.png` file, but should be named `.gif` regardless
    - `<ClassId>-bigIcon.gif`: should be a 32x32 pixel representation of the class, and could also be a `.png` file, but should be named `.gif` regardless

### `assets_as_xml`

The list of XML files provided through this variable should be fully-working asset instance XML files, either already generated (eg. by variable below) or manually created.

### `assets_as_yaml`

This variable is provided as a more convenient / readable way to specify asset instances than learning the XML format required by `assets_as_xml` above.

The list of YAML files provided through this variable are used to generate valid asset instance XMLs that are then loaded automatically. The structure of each YAML file should be as follows:

```yml
---

bundleId: <BundleId>
contains:
  - class: <ClassName>
    name: <name>
    contains:
      - class: <NestedClassName>
        name: <name>
        contains:
          ...
```

The `contains` substructure can be nested as many times as necessary to create the containment hierarhcy you require for your asset(s). Each sub-structure must have at a minimum the `class` and `name` defined.

In addition, any number of additional attributes can also be specified as permitted by your bundle definition and the default set of attributes for all objects (eg. `short_description`, `long_description`). Any bundle-defined attributes simply need to be prefixed with `$`. For example:

```yml
---

bundleId: TestBundle
contains:
  - class: Folder
    name: level1
    short_description: The top-level directory
    $filesystem: UNIX
    contains:
      - class: Folder
        name: level2
        short_description: The next level down in the directory structure
        contains:
          - class: File
            name: MyFile.txt
            short_description: A file that sits within /level1/level2/MyFile.txt
            $encoding: UTF-8
```

In this example the `TestBundle` bundle defines `Folder`s and `File`s, where `Folder`s can have a `filesystem` attribute defined and `File`s can have an `encoding` defined. Both can have `short_description`s because all objects in IGC have this attribute.

For attributes that allow multiple values, simply specify define the value for the attribute as a YAML list. In this example, the `users_with_access` attribute specific to the bundle allows multiple values, so we specify each value as part of a YAML list for that attribute:

```yml
---

bundleId: TestBundle
contains:
  - class: Folder
    name: root
    $users_with_access:
      - user123
      - user456
      - user789
```

Finally, the `names` shortcut exists for leaf-nodes of a containment hierarchy where all you need to specify is the `name` of each one -- this avoids needing to specify the same `class` over and over again for each leaf node:

```yml
---

bundleId: TestBundle
contains:
  - class: Folder
    name: root
    contains:
      - class: File
        names:
          - MyFile.txt
          - YourFile.txt
          - OtherFile.txt
```

### `flows_as_xml`

The list of XML files provided through this variable should be fully-working lineage flow XML files, either already generated (eg. by variable below) or manually created.

### `flows_as_yaml`

This variable is provided as a more convenient / readable way to specify asset instances than learning the XML format required by `flows_as_xml` above.

The list of YAML files provided through this variable are used to generate valid lineage flow XMLs that are then loaded automatically. The structure of each YAML file should be as follows:

```yml
---

assets:
  - class: <FullClassName>
    name: <name>
    contains:
      - class: <NestedFullClassName>
        name: <name>
        id: <unique identifier>
        contains:
          ...

flows:
  - name: <meaningful comment>
    within: <id>
    contains:
      - name: <meaningful comment>
        from:
          - <id>
          - ...
        to:
          - <id>
          - ...
      - ...
```

The `contains` substructure for `assets` can be nested as many times as necessary to create the containment hierarhcy you require for your asset(s). Each sub-structure must have at a minimum the `class` and `name` defined (in fact, any other attributes are simply ignored as they are unused by the lineage flow XML). Note that in this case you should specify fully-qualified class names, including the bundleId, eg. `$BundleId-ClassName`. This is to ensure you can combine both OpenIGC and native assets in a lineage flow (and create lineage flows spanning multiple OpenIGC bundles).

For any assets you plan to use as part of a flow, also include an explicit `id` attribute to specify how you will refer to them within the `flows` variable. This identifier should be unique within the YAML file, and should not contain any spaces or other special characters (other than `.` and `_`).

Each `name` in the `flows` variable is used as a comment in the generated XML, but does not actually appear in IGC itself.

Consider the following example:

```yml
---

assets:
  - class: $TestBundle-Folder
    name: root
    contains:
      - class: $TestBundle-File
        name: MyFile.txt
        id: MyFile.txt
      - class: $TestBundle-File
        name: YourFile.txt
        id: YourFile.txt
      - class: $TestBundle-File
        name: OtherFile.txt
        id: OtherFile.txt
  - class: $TestBundle-Command
    name: copy
    id: copy

flows:
  - name: Copy command to duplicate a file
    within: copy
    contains:
      - name: Copy from My to Your and Other
        from:
          - MyFile.txt
        to:
          - YourFile.txt
          - OtherFile.txt
```

In the example, we have a `TestBundle` that defines new objects representing `Folder`s, `File`s and `Command`s. The `assets` section defines only the objects we want to describe in lineage, including their containment hierarchy. For each asset we will use in lineage we have defined a unique `id` attribute.

In the `flows` section we then create the lineage: the outer `within` defines the process responsible for whatever action is being depicted in lineage, and the `contains` within that specifies the specific inputs and outputs of the action.

## License

Apache 2.0

## Author Information

Christopher Grote
