# Curso de iniciación al HPC-CIBER

Material de teoría y práctica para empezar a trabajar en el HPC-CIBER, el entorno de computación de alto rendimiento del CIBER-ISCIII. Lo organiza la Plataforma de Bioinformática de CIBERINFEC (BiPLAT).

Este repositorio es una adaptación al HPC-CIBER del curso [BU-ISCIII/introduction_to_hpc](https://github.com/BU-ISCIII/introduction_to_hpc), de la Unidad de Bioinformática del Instituto de Salud Carlos III, que es el repositorio original.

## Antes de empezar: dónde va cada cosa

**En el nodo de acceso no se lanza nada.** Ahí editas, organizas ficheros y envías trabajos. Todo cálculo, y también las copias grandes, va con `srun` o `sbatch`.

| Espacio | Para qué | En el curso |
|---|---|---|
| `/hpcciber/home/<usuario>` | Configuración y scripts personales pequeños. Poco espacio; no se analiza aquí. | Tu home |
| `/data-ciber/<área>/<proyecto>` | El proyecto: datos, scripts del análisis, documentación y resultados. Persistente. | `/data-ciber/infec/hpccourse` |
| `/scratch/<área>/<proyecto>` | Copia de trabajo mientras calculas. Rápido, temporal y compartido por todo CIBER. | `/scratch/infec/hpccourse` |

Flujo de trabajo: **/data-ciber → /scratch (calcular) → resultados a /data-ciber → limpiar /scratch**.

**Acceso:** consola del portal de Zscaler (PRA) en la IP acabada en `.10` (la completa se da en clase); como segunda opción, MobaXterm (versión instalable) con el cliente Zscaler.

## Programa

### Sesión 1 · Infraestructura HPC y fundamentos de Linux

- **Teoría:** [Introducción al HPC y sus componentes](slides/talk1_introduction_hpc.pdf) · [Introducción a Linux](slides/linux_intro.pdf)
- **Práctica 1:** [Comandos básicos de Linux](exercises/01_handson_linux/handson_linux1_BasicCommands.md)
- **Práctica 2:** [Manejo de ficheros](exercises/01_handson_linux/handson_linux2_FileProcessing.md)
- **Práctica 3:** [Usuarios y permisos](exercises/01_handson_linux/handson_linux3_Privileges.md)

### Sesión 2 · Conexión, transferencia de datos y SLURM

- **Teoría:** [Acceso, conexión y transferencia de datos](slides/talk3_access_connection_datatransfer.pdf) · [SLURM y directorios de trabajo](slides/talk4_filesystems_slurm.pdf)
- **Práctica 4:** [Acceso, estructura del proyecto y transferencia de datos](exercises/04_access/handson_access.md)
- **Práctica 5:** [Reservar recursos con srun](exercises/05_srun/handson_srun.md)

### Sesión 3 · Instalación de software: módulos, micromamba y contenedores

- **Teoría:** [Gestión de software y contenedores](slides/talk5_SoftwareManagement_and_ContainersinHPC.pdf)
- **Práctica 6:** [Gestión de software](exercises/06_software_management_hpc/handson_software_management.md)

### Sesión 4 · Scripting, paralelización e introducción a Nextflow

- **Teoría:** [Scripting y paralelización](slides/talk6_Scripting_and_Parallelization.pdf) · [Flujos reproducibles con Nextflow](slides/talk7_ReliableReproducible_ScientificWorkflows_Nextflow.pdf)
- **Práctica 7:** [Scripting y paralelización](exercises/07_handson_scripting_and_parallelization/handson_scripting_and_parallelization.md)
- **Práctica 8:** [Flujos con Nextflow](exercises/08_handson_scientific_workflows_nextflow/handson_scientificworkflows_nextflow.md)

### Sesión 5 · Monitorización, diagnóstico y resolución de incidencias

- **Práctica 9:** [Casos prácticos y problemas habituales](exercises/09_usecase_issues/handson_usecase_issues1.md)

## Licencia

[GPL-3.0](LICENSE), la misma que el repositorio original.
