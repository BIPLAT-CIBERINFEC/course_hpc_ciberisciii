# Tareas de los profesores

Lista de lo que hay que dejar listo antes del curso y de lo que falta por confirmar en cada práctica. Se actualiza con cada sección adaptada.

> **Rutas.** La ruta oficial del curso es `/data-ciber/infec/hpccourse` (y `/scratch/infec/hpccourse`), que creará el administrador de sistemas unas semanas antes del curso. Mientras tanto, las pruebas se hacen en `/data-ciber/infec/biplat/hpccourse` y `/scratch/infec/biplat/hpccourse`.

## 1. Con el administrador de sistemas (UTIC de CIBER)

- [ ] Crear el proyecto del curso: `/data-ciber/infec/hpccourse` y `/scratch/infec/hpccourse`, con el grupo `hpccourse`.
- [ ] Si hay prácticas con alumnos: crear las cuentas `alumno00` … `alumnoNN`, cada una con contraseña del HPC y acceso temporal a Zscaler.
- [ ] Dar a todos los alumnos y profesores lectura y escritura en `/data-ciber/infec/hpccourse` y `/scratch/infec/hpccourse`.
- [ ] Confirmar que las cuentas del curso pueden usar la partición `test` (hoy `sacctmgr show assoc` no devuelve nada).
- [ ] GPU: los nodos `gpu01`–`gpu02` no están disponibles. ¿Lo estarán para el curso? ¿Tendrán acceso los alumnos a la partición `gpu`? ¿Está `nvidia-smi` en esos nodos?
- [ ] Nodos `cn07`–`cn10` y `fn01` aparecían `down*` el 24/11. ¿Estarán disponibles?
- [ ] **Instalar Apptainer** (no hay Singularity ni Apptainer, ni como módulo ni en el sistema) en los nodos de cómputo. Hace falta para la práctica 6 (contenedores) y la 8 (Nextflow). Después, volver a lanzar `profesores/crear_entorno_comun.sh` para descargar las imágenes en `common/images`.
- [ ] RAxML en su versión híbrida MPI, como módulo compilado contra `openmpi5/5.0.3` (práctica 7). El resto del software va en el entorno común de micromamba.
- [ ] ¿Admite el HPC-CIBER autenticación por clave SSH a través de Zscaler? (práctica 4, ejercicio 4)
- [ ] ¿Limita SLURM la memoria por trabajo (cgroups)? Afecta al ejemplo de memoria agotada de la práctica 5.

## 2. Preparación técnica (profesores)

- [ ] **Avisar a los alumnos del autolimpiado de `/scratch`**: hoy no se aplica, pero se aplicará (plazo por confirmar). Lo que no estén usando, a `/data-ciber`.

- [ ] **Datos de prueba** en `<base>/datos_prueba`: los 10 FASTQ de [Zenodo 17207071](https://zenodo.org/records/17207071), de solo lectura. Desde un nodo de cómputo (sí tienen internet):
  ```bash
  srun --partition=test --mem=1G --time=00:30:00 bash -c '
    mkdir -p /data-ciber/infec/hpccourse/datos_prueba && cd /data-ciber/infec/hpccourse/datos_prueba
    for f in ERR2261314_1 ERR2261314_2 ERR2261315_1 ERR2261315_2 ERR2261318_1 ERR2261318_2 virus1_R1 virus1_R2 virus2_R1 virus2_R2; do
      wget -c -O "$f.fastq.gz" "https://zenodo.org/api/records/17207071/files/$f.fastq.gz/content"
    done
    md5sum *.fastq.gz > md5sum.md5'
  chmod -R a-w /data-ciber/infec/hpccourse/datos_prueba
  ```
- [ ] Copiar también a `datos_prueba` el fichero de la práctica de Linux `microarray_adenoma_hk69.csv` (por si el nodo de acceso no tiene internet).
- [ ] **micromamba y entorno común del curso.** Una vez, en un nodo de cómputo:
  ```bash
  # pruebas: CURSO_BASE=/data-ciber/infec/biplat/hpccourse
  srun --partition=test --cpus-per-task=4 --mem=8G --time=01:00:00 \
    bash profesores/crear_entorno_comun.sh
  ```
  Crea la carpeta común del curso, `<base>/common`, que los alumnos solo leen: micromamba en `common/bin/micromamba`, el entorno en `common/envs/curso_hpc` y las imágenes de Apptainer en `common/images` (por ahora `fastp.sif`). Todo queda protegido contra escritura. Paquetes ([curso_hpc.yml](curso_hpc.yml)) y prácticas que los usan:

  | Paquete | Prácticas |
  |---|---|
  | fastqc | 5 (srun), 7 (scripting), 9 (casos) |
  | multiqc | 7 |
  | seqkit | 6 (ejemplo de entorno) |
  | fastp | 9 (en la 6 se usa como imagen de Apptainer: `common/images/fastp.sif`) |
  | spades | 7 (OpenMP) |
  | nextflow | 8 |

  En la práctica 6 cada alumno crea además su propio entorno pequeño (en su home), para aprender a hacerlo.
- [ ] Comprobar como `alumno00` que se lee `common/` (`bin/micromamba`, `envs/curso_hpc`, `images/`) con `micromamba run -p`, `micromamba activate <ruta>` y `apptainer exec`.
- [ ] Ensayar con varios alumnos a la vez el `micromamba create` y el `pip install` de la práctica 6 (descargan de internet). Si va lento, pasar esa parte a demo.
- [ ] Probar el entorno: `micromamba run -p <base>/common/envs/curso_hpc fastqc --version` (y el resto) desde un nodo de cómputo.
- [ ] Carpeta de referencia del profesor (`<AAAAMMDD>_HPC-COURSE_profesor00`) con la estructura esperada al terminar las prácticas:
  ```
  <AAAAMMDD>_HPC-COURSE_profesor00
  ├── ANALYSIS
  │   ├── 00-reads                          enlaces a ../../RAW con nombres <muestra>_R1/_R2.fastq.gz
  │   ├── 01-fastqc                         informes FastQC + logs/
  │   ├── 06-software-management
  │   ├── 07-scripting-and-parallelization  scripts .sbatch + data/raxml_demo.phy
  │   ├── 08-scientific-workflows-nextflow
  │   └── samples_id.txt
  ├── DOC
  ├── RAW                                   FASTQ originales + md5sum.md5
  ├── REFERENCES
  ├── RESULTS
  └── TMP
  ```
- [ ] Imágenes de `nf-core/demo` (práctica 8) en `<base>/common/images`, cuando haya Apptainer.

## 3. Pendientes de confirmar en las prácticas

Cada uno aparece en la práctica como `[CONFIRMAR: …]`. Se resuelven al final, antes del curso.

| Práctica | Qué confirmar |
|---|---|
| 1 · Linux (`handson_linux2_FileProcessing.md`) | Salida a internet desde el nodo de acceso (`wget`) |
| 4 · Acceso (`handson_access.md`) | Formato real de `id` · permisos reales de las carpetas del proyecto · claves SSH a través de Zscaler · que el límite del PRA es 50 MB por fichero |
| 6 · Software (`handson_software_management.md`) | Plazo del autolimpiado de `/scratch` · mensaje de `pip install` sin entorno (hay `/usr/bin/pip` en los nodos) y salida real de `pip list` · versión de micromamba en `common/bin` · que los alumnos pueden activar `common/envs/curso_hpc` y versiones de seqkit y FastQC · `R` fuera del PATH y salida de `module load R/4.2.1` · salidas de `module avail/spider openmpi` · mayúsculas en `module spider` · cómo se carga Apptainer · que las imágenes de `common/images` funcionan en los nodos |
| 5 · srun (`handson_srun.md`) | Mensaje de memoria agotada (cgroups) · salida real de `lscpu` en un nodo de cómputo · `nvidia-smi` y acceso a `gpu` · `sacct` activo y visible para el alumno · FastQC instalado en el entorno común |

## 4. Ya comprobado (25/11/2026)

- Memoria máxima de un nodo (fat, `fn01`): 2.058.200 MB (~2 TB). Particiones y CPUs como en las prácticas; `gpu` tiene `gpu:1` por nodo.
- No hay módulos de FastQC, MultiQC, SPAdes, RAxML, Nextflow, Java ni Singularity/Apptainer; sí `openmpi5/5.0.3`. Se usará Apptainer (decisión del 26/11).
- Disponibles: `seff`, `sstat`, `tree`, `watch`, `nano`, `less`, `man`, `rsync`, `md5sum`, `python3`, `curl`.
- Los nodos de cómputo tienen salida a internet (micromamba, conda, quay.io, depot de Galaxy, GitHub).
- No hay comando `quota`; `df` muestra el volumen compartido, no la cuota.
- En la ruta de pruebas (`/data-ciber/infec/biplat/hpccourse` y su espejo en `/scratch`) se pueden crear carpetas.
- Ficheros de más de 50 MB: por `scp` o `rsync`.
