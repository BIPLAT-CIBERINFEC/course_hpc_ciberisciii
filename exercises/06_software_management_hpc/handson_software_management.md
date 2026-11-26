# Curso de iniciación al HPC-CIBER

BiPLAT-CIBERINFEC · adaptado del curso de BU-ISCIII

## Práctica 6: Gestión de Software en HPC

Bienvenido a la sesión práctica sobre la gestión de software en nuestro HPC. Hoy cubriremos tres temas principales:

- [Curso de iniciación al HPC-CIBER](#curso-de-iniciación-al-hpc-ciber)
  - [Práctica 6: Gestión de Software en HPC](#práctica-6-gestión-de-software-en-hpc)
    - [Notas importantes](#notas-importantes)
  - [1. Entornos Virtuales \& Gestores de Software](#1-entornos-virtuales--gestores-de-software)
    - [Usar el entorno común del curso: activate, srun y sbatch](#usar-el-entorno-común-del-curso-activate-srun-y-sbatch)
    - [(Extra) Cómo compartir entornos virtuales entre usuarios con micromamba](#extra-cómo-compartir-entornos-virtuales-entre-usuarios-con-micromamba)
    - [2.2 Otros gestores: Easybuild](#22-otros-gestores-easybuild)
  - [3. Contenedores: Docker \& Apptainer](#3-contenedores-docker--apptainer)
    - [3.1 Las imágenes comunes del curso](#31-las-imágenes-comunes-del-curso)
    - [3.2 Descargar tu propia imagen](#32-descargar-tu-propia-imagen)
    - [3.3 Lanzar el contenedor con srun](#33-lanzar-el-contenedor-con-srun)
    - [3.4 Otros conceptos importantes sobre Apptainer](#34-otros-conceptos-importantes-sobre-apptainer)

### Notas importantes

- El acceso se realiza al nodo de acceso `login01` como en la práctica 4: consola del portal de Zscaler o `ssh <usuario>@<IP acabada en .10>`.
- No se deben ejecutar cálculos en el nodo de acceso, solo gestionar ficheros y enviar trabajos a la cola. **Instalar software también cuenta**: la instalación de entornos consume CPU y memoria, por eso en esta práctica la hacemos dentro de un nodo de cómputo (`srun --pty bash`).
- Los datos de usuario se organizan en diferentes espacios de trabajo:

  - `/hpcciber/home/<usuario>` → configuración y scripts personales pequeños.
  - `/data-ciber/<área>/<proyecto>` → proyecto persistente. El del curso es `/data-ciber/infec/hpccourse`.
  - `/scratch/<área>/<proyecto>` → ejecución temporal de trabajos. El del curso es `/scratch/infec/hpccourse`. **Ojo:** el HPC-CIBER aplicará una política de autolimpiado de los ficheros inactivos de `/scratch`. Hoy no está activa, pero no dejes ahí nada que no estés usando y guarda siempre los resultados en `/data-ciber`. `[CONFIRMAR: plazo de la política de autolimpiado; el manual habla de unos 45 días]`
- No almacenar información no relacionada con los cálculos autorizados.
- En los comandos, sustituye `<AAAAMMDD>` por la fecha de tu carpeta `/data-ciber/infec/hpccourse/<AAAAMMDD>_HPC-COURSE_${USER}` (práctica 4).

## 1. Entornos Virtuales & Gestores de Software

- **¿Por qué usar entornos virtuales?**
  Principalmente para aislar dependencias y evitar conflictos, pero también sirve para organizar todo el software necesario para una tarea en el mismo lugar.

- **¿Cómo crear un entorno virtual?**
  Existen muchas herramientas que ayudan a crear entornos virtuales. Softwares como **conda o mamba** incluso los gestionan para simplificar la instalación de software y evitar conflictos. En el HPC-CIBER usaremos **micromamba**.

- En primer lugar, sino estamos ya conectados, vamos a conectarnos al HPC como hemos visto anteriormente (práctica 4): `ssh <usuario>@<IP acabada en .10>` o la consola de Zscaler.

- Para no instalar nada en el nodo de acceso, pedimos una **sesión interactiva en un nodo de cómputo** y trabajamos dentro de ella hasta que se indique lo contrario (el prompt pasará de `login01` a un nodo `cnXX`):

  ```bash
  cd /data-ciber/infec/hpccourse/<AAAAMMDD>_HPC-COURSE_${USER}/ANALYSIS
  mkdir -p 06-software-management
  srun --partition=test --cpus-per-task=4 --mem=16G --time=02:00:00 --chdir /data-ciber/infec/hpccourse/<AAAAMMDD>_HPC-COURSE_${USER}/ANALYSIS/06-software-management --pty bash -l
  hostname # debe ser un nodo de cómputo (cnXX), no login01
  pwd
  ```

  Output:

  ```bash
  cn01
  /data-ciber/infec/hpccourse/<AAAAMMDD>_HPC-COURSE_alumno00/ANALYSIS/06-software-management
  ```

  - Una manera sencilla de crear un entorno virtual es con `venv`, una herramienta propia de Python. Lo creamos en la carpeta de esta práctica, no en el home:

    ```bash
    pwd # estamos en ANALYSIS/06-software-management
    ls
    python3 -m venv bioenv # Crear el entorno
    source bioenv/bin/activate # Activar el entorno
    ```

    Verás `(bioenv)` a la izquierda del prompt indicando que está activado. `pip` se instala por defecto, así que podemos aprovecharlo para instalar librerías ya que ayuda a gestionar las dependencias:

    ```bash
    pip install --upgrade pip # Upgrade pip version, default is too old
    pip install numpy rich requests # Instalar paquetes con pip
    python3 -c 'import numpy as np; print(np.random.rand(10))' # Comprobar instalación

    # Output (Numeros aleatorios)
    # [0.82817341 0.32560646 0.96031543 0.49938711 0.28076754 0.5633077
    # 0.62029871 0.13840926 0.12178352 0.74080816]
    ```

    - Vamos a ver que pasa si lo desinstalamos:

    ```bash
    pip uninstall -y numpy # -y Evita que nos pregunte si estamos seguros
    python3 -c 'import numpy' # Esperado -> ModuleNotFoundError

    # Output
    # Traceback (most recent call last):
    # File "<string>", line 1, in <module>
    # ModuleNotFoundError: No module named 'numpy'

    deactivate # Salir del entorno virtual
    ```

    Nota: Puedes salir en cualquier momento del entorno virtual con `deactivate`.

- **¿Cómo trabajar con entornos virtuales en nuestro HPC?**
  En este ejercicio usaremos **seqkit** para inspeccionar archivos de secuencias.

  - Veamos si lo tenemos instalado:

    ```bash
    seqkit --help # <-- Command 'seqkit' not found
    ```

  - Intentemos instalarlo con pip:

    ```bash
    pip install seqkit
    ```

  - Bueno, eso no salió como esperábamos ¿verdad? Como vimos en la clase teórica, pip no crea ninguna virtualización, solo gestiona paquetes y dependencias. Por lo tanto, si intentáramos instalar algo con pip, terminaríamos instalándolo para todos los demás usuarios del HPC. Esa es la razón principal por la que **pip no está instalado globalmente en nuestro HPC**. `[CONFIRMAR: que en los nodos de cómputo del HPC-CIBER no hay pip fuera de un entorno virtual; si lo hubiera, el comando anterior daría otro error]`

  - **Discusión:** ¿Se te ocurre alguna alternativa para instalar seqkit?
  Vamos a ver si lo tenemos disponible dentro de **bioenv**, el entorno virtual que creamos previamente.

    ```bash
    source bioenv/bin/activate
    pip list # Comando para ver qué paquetes están instalados por pip

    # Output (las versiones dependen de la versión de Python del nodo)

    # Package            Version
    # ------------------ ---------
    # certifi            2025.4.26
    # charset-normalizer 2.0.12
    # commonmark         0.9.1
    # dataclasses        0.8
    # idna               3.10
    # numpy              1.19.5
    # pip                21.3.1
    # Pygments           2.14.0
    # requests           2.27.1
    # rich               12.6.0
    # setuptools         39.2.0
    # typing_extensions  4.1.1
    # urllib3            1.26.20
    ```

    `[CONFIRMAR: salida real de pip list en el HPC-CIBER (versión de Python de los nodos de cómputo)]`

    No es nuestro caso, pero podemos intentar instalarlo con pip.

    ```bash
    pip install seqkit

    # Output esperado:
    # ERROR: Could not find a version that satisfies the requirement seqkit (from versions: none)
    # ERROR: No matching distribution found for seqkit
    ```

    Parece que `seqkit` no está disponible en el repositorio de pip [https://pypi.org/](https://pypi.org/). En este caso, usaremos **micromamba** para crear un entorno aislado ya que seqkit si se encuentra accesible en los repositorios de micromamba. Una vez activado el entorno, podremos instalar y usar `seqkit` de manera segura dentro de él. <br><br>

- **Micromamba:** Nuestro gestor de entornos favorito, ya que es especialmente rápido y ligero. En el HPC-CIBER **no hace falta descargarlo**: hay un micromamba compartido para el curso en `/data-ciber/infec/hpccourse/common/bin/micromamba`. (Fuera del curso, para tener el tuyo propio bastaría con `curl -Ls https://micro.mamba.pm/api/micromamba/linux-64/latest | tar -xvj bin/micromamba`, que deja el binario en `./bin/micromamba`. No lo ejecutes ahora.) Sal de `bioenv` primero (`deactivate`) y comprobamos que funciona lanzando el comando y viendo la ayuda:

```bash
deactivate
ls -l /data-ciber/infec/hpccourse/common/bin/micromamba
/data-ciber/infec/hpccourse/common/bin/micromamba
```

- Output:

```bash
Version: 2.3.2



micromamba [OPTIONS] [SUBCOMMAND]


OPTIONS:
  -h,     --help              Print this help message and exit
          --version

Configuration options:
          --rc-file FILE1 FILE2...
                              Paths to the configuration files to use
          --no-rc             Disable the use of configuration files
          --no-env            Disable the use of environment variables

Global options:
  -v,     --verbose           Set verbosity (higher verbosity with multiple -v, e.g. -vvv)
          --log-level ENUM:value in {critical->5,debug->1,error->4,info->2,off->6,trace->0,warning->3} OR {5,1,4,2,6,0,3}
                              Set the log level
  -q,     --quiet             Set quiet mode (print less output)
  -y,     --yes               Automatically answer yes on prompted questions
          --json              Report all output as json
          --offline           Force use cached repodata
          --dry-run           Only display what would have been done
          --download-only     Only download and extract packages, do not link them into
                              environment.
          --experimental      Enable experimental features
          --use-uv            Whether to use uv for installing pip dependencies. Defaults to
                              false.

Prefix options:
  -r,     --root-prefix PATH  Path to the root prefix
  -p,     --prefix PATH       Path to the target prefix
          --relocate-prefix PATH
                              Path to the relocation prefix
  -n,     --name NAME         Name of the target prefix

SUBCOMMANDS:
  shell                       Generate shell init scripts
  create                      Create new environment
  install                     Install packages in active environment
  update                      Update packages in active environment
  self-update                 Update micromamba
  repoquery                   Find and analyze packages in active environment or channels
  remove, uninstall           Remove packages from active environment
  list                        List packages in active environment
  package                     Extract a package or bundle files into an archive
  clean                       Clean package cache
  config                      Configuration of micromamba
  info                        Information about micromamba
  constructor                 Commands to support using micromamba in constructor
  env                         See `mamba/micromamba env --help`
  activate                    Activate an environment
  run                         Run an executable in an environment
  ps                          Show, inspect or kill running processes
  auth                        Login or logout of a given host
  search                      Find packages in active environment or channels
                              This is equivalent to `repoquery search` command
```

`[CONFIRMAR: versión de micromamba instalada en /data-ciber/infec/hpccourse/common/bin (la del ejemplo es 2.3.2)]`

- Para hacer que el comando micromamba persista en nuestro entorno cuando reiniciemos la terminar, o salgamos y entremos de nuevo en el hpc. Tenemos que añadir una serie de cambios a nuestro bashrc. Además de hacer el setup de la carpeta donde se van a instalar todos los entornos (la raíz de micromamba, `-r`). La ponemos en la carpeta de esta práctica, no en el home:

```bash
/data-ciber/infec/hpccourse/common/bin/micromamba shell init -s bash -r /data-ciber/infec/hpccourse/<AAAAMMDD>_HPC-COURSE_${USER}/ANALYSIS/06-software-management/micromamba
```

- Este comando añadirá este bloque a tu .bashrc. Puedes comprobarlo con `cat ~/.bashrc`

```bash
# >>> mamba initialize >>>
# !! Contents within this block are managed by 'mamba shell init' !!
export MAMBA_EXE='/data-ciber/infec/hpccourse/common/bin/micromamba';
export MAMBA_ROOT_PREFIX='/data-ciber/infec/hpccourse/<AAAAMMDD>_HPC-COURSE_alumno00/ANALYSIS/06-software-management/micromamba';
__mamba_setup="$("$MAMBA_EXE" shell hook --shell bash --root-prefix "$MAMBA_ROOT_PREFIX" 2> /dev/null)"
if [ $? -eq 0 ]; then
    eval "$__mamba_setup"
else
    alias micromamba="$MAMBA_EXE"
fi
unset __mamba_setup
# <<< mamba initialize <<<
```


- Para que se apliquen los cambios a nuestra terminal actual recargamos la configuración de nuestra terminal:

```bash
source ~/.bashrc
```

- Ahora ya podemos utilizar micromamba invocándolo directamente por su nombre. Micromamba cuenta con un entorno `base` pre-instalado: podemos activarlo con `micromamba activate`. Cuando se haya activado aparecerá `(base)` a la izquierda de nuestra linea de comandos. Para salir, utiliza `micromamba deactivate`.

- Por último vamos a configurar nuestro `.condarc` (micromamba lee el mismo fichero de configuración que conda). Es un fichero pequeño de configuración personal, así que va en el home:

```bash
touch ~/.condarc
```

- Escribimos lo siguiente en el fichero con `nano` o `vim`:

```bash
auto_activate_base: false
channels:
  - conda-forge
channel_priority: strict
```
- **IMPORTANTE**: Aseguraos de que **solo** tiene ese contenido, nada más.
<br>

- Con esto ya tendríamos un entorno virtual, pero nosotros vamos a ir más allá, creando un entorno virtual personalizado con `micromamba create`:

```bash
micromamba create -y -n mamba_env python==3.12.0 pip twine -c conda-forge
```

- Output:

```bash
  #
  # Transaction finished
  #
  # To activate this environment, use:
  #
  #     micromamba activate mamba_env
  #
  # Or to execute a single command in this environment, use:
  #
  #    micromamba run -n mamba_env mycommand
```

- Vamos a explicar cada parámetro en profundidad:

  - `-y` sirve para no tener que confirmar la instalación
  - `-n` se usa para asignar el **nombre del entorno**
  - `python==3.12.0 pip twine` son los **paquetes iniciales** a instalar: en este caso especificamos `python` con la versión `3.12.0` y `pip`.
  - `-c` indica el **channel o canal** donde va a buscar los paquetes.

  **Podemos establecer tantos paquetes iniciales como queramos**, siempre que estén disponibles en los canales de conda configurados.

  - Activemos nuestro entorno virtual:

  ```bash
  micromamba activate mamba_env
  ```

  - Tus paquetes ahora están aislados del   sistema global. Verás `(mamba_env)` añadido en la esquina   izquierda del prompt de tu terminal como indicador de que   el entorno está activado.

  - Puedes probar `pip list`   ahora, ya que estará disponible dentro del entorno   virtual. Esto listará todos los paquetes instalados con   pip. Intenta hacer lo mismo en el anterior virtualenv   `bioenv` para ver qué ocurre (_pista: primero necesitarás   salir con `micromamba deactivate`_).

  - Veamos si `seqkit` está disponible en pip o micromamba para poder instalarlo:
  Pip no tiene un comando oficial para buscar un paquete, debes ir a su página web y usar el navegador para encontrarlo [https://pypi.org/search](<https://pypi.org/>  search). Es crucial inspeccionarlo antes de instalar, ya que podría haber un paquete con el mismo nombre que el que quieres pero con diferente funcionalidad.

  **Ejemplo**: `taranis` en pip es un wrapper de una API meteorológica, pero en bioconda es un pipeline para wg/cgMLST allele calling.

  - En este caso, `Seqkit` no está disponible a través de pip, por lo que nuestra mejor opción es instalarlo con micromamba.

  - Veamos si `seqkit` está disponible en micromamba:

  ```bash
  micromamba search seqkit
  # Getting repodata from channels...

  # nodefaults/  # linux-64                                         Using   # cache
  # nodefaults/  # noarch                                           Using   # cache
  # conda-forge/noarch                                  22.3MB   # @  31.6MB/s  0.6s
  # conda-forge/linux-64                                47.0MB   # @  51.1MB/s  0.9s
  # No entries matching "seqkit" found
  # Try looking in a different channel with '-c, --channel'.
  ```

  Como puedes ver no aparece. Esto es debido a que seqkit solo se encuentra disponible en [https://conda.anaconda.org/bioconda](https://conda.anaconda.org/bioconda). Esto significa que si no tenemos el canal `bioconda` añadido a nuestra configuración, no podremos descargarlo con micromamba.

  - Puedes comprobar la lista de canales accesibles con:

  ```bash
  micromamba config get channels
  ```

  Podrías ver algo como lo siguiente:

  ```bash
  channels:
      - conda-forge
  ```

  Vamos a indicarle que busque el paquete en `bioconda`:

  ```bash
  micromamba install seqkit -c bioconda
  ```

  - Si quieres **añadir un canal por defecto**, puedes hacerlo modificando la sección `channels` en el archivo de configuración `~/.condarc`. El orden de los canales es importante para evitar conflictos, la configuración actual que recomienda bioconda es esta, pero puede cambiar con el tiempo:

  > Nota primer canal con más prioridad que el segundo

  ```bash
  channels:
      - conda-forge
      - bioconda
  ```

  Ahora ya no tendrás que indicar bioconda como canal al instalar ya que lo usará por defecto.

  - **Consejo**: si quieres instalar paquetes de   Python, usa `pip install` ya que es el repositorio de   paquetes de Python más grande, pero para herramientas más   complejas como `bedtools` o ``fastp utiliza **micromamba** o   **conda**.

  - Ahora que ya tenemos instalado `seqkit`, vamos a hacer una pequeña prueba para ver que funciona. Seguimos dentro de la sesión interactiva del nodo de cómputo, así que no hace falta `srun` para cada comando:

  ```bash
  micromamba activate mamba_env
  seqkit version
  #Output
  #seqkit v2.10.1
  ```

  ```bash
  # zcat permite leer archivos comprimidos
  zcat ../00-reads/virus1_R1.fastq.gz | seqkit stats

  #Output
  #file  format  type  num_seqs     sum_len  min_len  avg_len  max_len
  #-     FASTQ   DNA    142,672  15,874,146       35    111.3      151
  #
  micromamba deactivate
  ```

  - Cuando termines, sal de la sesión interactiva para volver al nodo de acceso y liberar el nodo de cómputo (el prompt vuelve a `login01`):

  ```bash
  exit
  ```

### Usar el entorno común del curso: activate, srun y sbatch

Instalar el software de cada herramienta en cada alumno es lento. Para el curso hay un **entorno común** ya instalado, con FastQC, MultiQC, seqkit, fastp, SPAdes y Nextflow, en `/data-ciber/infec/hpccourse/common/envs/curso_hpc`. Solo tienes que leerlo, no modificarlo. Hay tres maneras de usarlo, según dónde trabajes:

1. **Sesión interactiva (`activate`)**: para probar cosas a mano en un nodo de cómputo.

```bash
srun --partition=test --cpus-per-task=2 --mem=4G --time=00:30:00 --pty bash
micromamba activate /data-ciber/infec/hpccourse/common/envs/curso_hpc
seqkit version
fastqc --version
micromamba deactivate
exit
```

Output:

```bash
seqkit v2.10.1
FastQC v0.12.1
```

`[CONFIRMAR: versiones reales de seqkit y FastQC del entorno común y que el alumno puede activarlo (lectura)]`

2. **`srun` (`micromamba run`)**: un comando suelto, lanzado desde el nodo de acceso pero ejecutado en un nodo de cómputo. No hace falta activar nada; se indica la ruta del entorno con `-p`:

```bash
cd /data-ciber/infec/hpccourse/<AAAAMMDD>_HPC-COURSE_${USER}/ANALYSIS/06-software-management
srun --partition=test --cpus-per-task=1 --mem=1G --time=00:05:00 \
  /data-ciber/infec/hpccourse/common/bin/micromamba run -p /data-ciber/infec/hpccourse/common/envs/curso_hpc \
  seqkit stats ../00-reads/virus1_R1.fastq.gz
```

Output:

```bash
file                        format  type  num_seqs     sum_len  min_len  avg_len  max_len
../00-reads/virus1_R1.fastq.gz  FASTQ   DNA    142,672  15,874,146       35    111.3      151
```

3. **`sbatch` (`micromamba run`)**: lo mismo, pero dentro de un script. En un trabajo con `sbatch` **no** se activan entornos con `micromamba activate` (el script no lee tu `.bashrc`): se usa siempre `micromamba run -p`.

```bash
# con srun y sbatch el directorio de envío es el directorio actual
cd /data-ciber/infec/hpccourse/<AAAAMMDD>_HPC-COURSE_${USER}/ANALYSIS/06-software-management
mkdir -p logs
cat > seqkit_stats.sbatch <<'EOF'
#!/bin/bash
#SBATCH --job-name=seqkit_stats
#SBATCH --partition=test
#SBATCH --cpus-per-task=1
#SBATCH --mem=1G
#SBATCH --time=00:05:00
#SBATCH --output=logs/%x_%j.out

echo "Host: $(hostname)"
/data-ciber/infec/hpccourse/common/bin/micromamba run -p /data-ciber/infec/hpccourse/common/envs/curso_hpc \
  seqkit stats ../00-reads/virus1_R1.fastq.gz ../00-reads/virus1_R2.fastq.gz
EOF
sbatch seqkit_stats.sbatch
squeue -u "$USER"
# espera a que squeue -u "$USER" no muestre el trabajo (repítelo hasta que desaparezca) y entonces:
cat logs/seqkit_stats_*.out
# si el log aún estaba vacío o no existía, repite el cat cuando el trabajo haya terminado
cat logs/seqkit_stats_*.out
```

- ¿En qué nodo se ha ejecutado el trabajo? ¿Por qué hemos usado rutas relativas (`../00-reads`) en el script?

### (Extra) Cómo compartir entornos virtuales entre usuarios con micromamba

- Configura `.condarc` para utilizar un directorio de entornos común para otros usuarios. `/data-ciber/infec/hpccourse/common/envs` es de solo lectura para ti, así que **se añade** a la lista (no sustituye a tu directorio de entornos):

    ```bash
    nano ~/.condarc
    envs_dirs:
       - /data-ciber/infec/hpccourse/<AAAAMMDD>_HPC-COURSE_<usuario>/ANALYSIS/06-software-management/micromamba/envs
       - /data-ciber/infec/hpccourse/common/envs
    ```

  A partir de ahora, tendrás disponibles todos los entornos creados y guardados en esas localizaciones. Y todos los usuarios que hagan lo mismo tendrán acceso a la misma lista de entornos.

### 2.2 Otros gestores: Easybuild

- Easybuild es un gestor de software especialmente pensado para sistemas HPC como el nuestro. Este gestor permite a los administradores empaquetar software en módulos o `modules`. Esto hace accesibles a los usuarios múltiples versiones de un mismo software de forma rápida y eficaz.
<br>
- Vamos a probar un ejemplo con R. Abre de nuevo una sesión interactiva en un nodo de cómputo e intentemos iniciar una sesión de R:

```bash
srun --partition=test --cpus-per-task=2 --mem=4G --time=00:30:00 --pty bash -l
R
# Output
# -bash: R: command not found
```

`[CONFIRMAR: que R no está en el PATH del sistema en los nodos de cómputo]`

- Como podemos ver, R no está instalado a nivel de sistema (no es accesible directamente para los usuarios). Sin embargo, podemos acceder a R en el HPC a través de `modules`

```bash
module load R/4.2.1
R
"
Output

R version 4.2.1 (2022-06-23) -- "Funny-Looking Kid"
Copyright (C) 2022 The R Foundation for Statistical Computing
Platform: x86_64-pc-linux-gnu (64-bit)

R is free software and comes with ABSOLUTELY NO WARRANTY.
You are welcome to redistribute it under certain conditions.
Type 'license()' or 'licence()' for distribution details.

  Natural language support but running in an English locale

R is a collaborative project with many contributors.
Type 'contributors()' for more information and
'citation()' on how to cite R or R packages in publications.

Type 'demo()' for some demos, 'help()' for on-line help, or
'help.start()' for an HTML browser interface to help.
Type 'q()' to quit R.

> Aquí podréis lanzar comandos de R
ctrl+D para salir y pulsar "n" (no guardar)
"
```

`[CONFIRMAR: salida real de R tras module load R/4.2.1 (plataforma y si el módulo carga antes sus dependencias, p. ej. el compilador gnu)]`

Aunque esto pueda parecer engorroso, si sólo tuvieramos una sóla versión de R instalada a nivel de sistema, impediría a los usuarios ejecutar software que requiera de versiones concretas de R para su funcionamiento.

- **¿Cómo listar los módulos accesibles en el HPC?**.
Para ello bastará con utilizar `module avail`. En el output veremos una gran lista de módulos: compiladores (`gnu13`, `intel`), librerías MPI (`openmpi5`, `mpich`), librerías científicas (`openblas`, `hdf5`, `netcdf`, `boost`), R y paquetes de Python (`py3-numpy`, `py3-scipy`), EasyBuild o `cmake`, entre otros. `[CONFIRMAR: agrupación de módulos por categorías en la salida de module avail del HPC-CIBER]`
Para cada módulo veremos el nombre del módulo seguido por `/` y la versión del software contenido (ej: `R/4.2.1`).

  **Ojo:** a día de hoy, FastQC, MultiQC, SPAdes, RAxML, Nextflow, Java y Apptainer no están disponibles como módulo en el HPC-CIBER. Por eso, para esas herramientas usamos el entorno común de micromamba del apartado anterior.
- Podemos utilizar `module avail <regex>` para buscar modulos por su nombre o parte de éste. Por ejemplo, para buscar todas las versiones de OpenMPI disponibles:

```bash
module avail openmpi

"
Output

   openmpi5/5.0.3

  Where:
   D:  Default Module

Use "module spider" to find all possible modules and extensions.
Use "module keyword key1 key2 ..." to search for all possible modules matching any of the "keys".
"
```

`[CONFIRMAR: salida real de module avail openmpi (ruta de los módulos y otras versiones)]`

Otra opción más dirigida es `module spider`. La principal diferencia con `module avail`es que `spider` te devuelve cada paquete de forma individualizada con una descripción y sus versiones disponibles, en vez de un listado genérico. Vamos a repetir la búsqueda de las versiones de OpenMPI con esta opción:

```bash
module spider openmpi5

" Output
----------------------------------------------------------------------------
  openmpi5:
----------------------------------------------------------------------------
    Description:
      [descripción del módulo]

     Versions:
        openmpi5/5.0.3

----------------------------------------------------------------------------
  For detailed information about a specific "openmpi5" package (including how to load the modules) use the module's full name.
  For example:

     $ module spider openmpi5/5.0.3
----------------------------------------------------------------------------
"
```

`[CONFIRMAR: salida real de module spider openmpi5]`

Es importante mencionar que es **case-sensitive** por lo que no es lo mismo buscar `R` que `r`. `[CONFIRMAR: sensibilidad a mayúsculas de module spider/avail en el Lmod del HPC-CIBER]` Como esta última opción nos enseñará todos los paquetes que contengan el texto buscado en alguna parte de su nombre, podemos reducir la búsqueda con una expresión regular incluyendo el parámetro `-r`:

```bash
module -r spider openmpi

" Output
----------------------------------------------------------------------------
  openmpi5:
----------------------------------------------------------------------------
    Description:
      [descripción del módulo]

     Versions:
        openmpi5/5.0.3

----------------------------------------------------------------------------
  For detailed information about a specific "openmpi5" package (including how to load the modules) use the module's full name.
  For example:

     $ module spider openmpi5/5.0.3
----------------------------------------------------------------------------
"
```

`[CONFIRMAR: salida real de module -r spider openmpi]`

- **Prueba por tu cuenta** a lanzarlo ahora sin `-r`. ¿Qué diferencias ves? (Pista: `module spider openmpi` sin `-r` te sugerirá `openmpi5`.)
<br>

- Si quieres comprobar **qué módulos están activos** en tu sesión, puedes ejecutar `module list`.
Cuando termines de usar un módulo, puedes ejecutar `module unload <module_name>` para descargarlo de tu sesión, o `module purge` para descargar todos los módulos activos.

**Puedes combinar modules y entornos virtuales**: Por ejemplo, puedes iniciar el entorno `mamba_env` de micromamba y se mantendrán cargados los módulos que tuvieras cargados, o cargar módulos desde dentro, como prefieras.

- Cuando termines, sal de la sesión interactiva:

```bash
exit
```

## 3. Contenedores: Docker & Apptainer

`[CONFIRMAR: que Apptainer está instalado y cómo se carga (módulo o sistema) en los nodos de cómputo]`

- **¿Por qué contenedores?**
  Portabilidad y reproducibilidad de entornos de software.

- **Práctica:**
  Desafortunadamente, no tenemos Docker disponible en nuestro HPC. **Apptainer** (el sucesor de Singularity, con los mismos comandos) es un buen reemplazo de Docker ya que gestiona contenedores y además está **específicamente diseñado para sistemas HPC**: el contenedor corre con tu usuario, sin permisos de administrador.

- En este ejercicio usaremos **fastp** para recortar y filtrar por calidad las lecturas de una muestra. Trabaja desde una sesión interactiva en un nodo de cómputo:

```bash
srun --partition=test --cpus-per-task=2 --mem=4G --time=00:30:00 --pty bash -l
apptainer --version
```

### 3.1 Las imágenes comunes del curso

Igual que el entorno de micromamba, el curso tiene una carpeta común con imágenes de Apptainer ya descargadas, que todos podéis usar (solo lectura):

```bash
ls -lh /data-ciber/infec/hpccourse/common/images/
# fastp.sif   ...
```

`[CONFIRMAR: imágenes que deja el profesor en common/images]`

Ejecutar un programa de una imagen es `apptainer exec <imagen> <comando>`:

```bash
apptainer exec /data-ciber/infec/hpccourse/common/images/fastp.sif fastp --version
```

`apptainer exec` ejecuta un comando con todo lo que hay instalado dentro del contenedor, sin abrir una sesión en él. En cambio, `apptainer shell` te abre una terminal dentro del contenedor (sales con `exit` o `Ctrl+D`):

```bash
apptainer shell /data-ciber/infec/hpccourse/common/images/fastp.sif
fastp --help
exit
```

### 3.2 Descargar tu propia imagen

Existen muchos repositorios de contenedores, siendo [https://hub.docker.com](https://hub.docker.com) el más común. Para herramientas bioinformáticas recomendamos:

- [galaxy index](https://depot.galaxyproject.org/singularity/)
- [biocontainers registry](https://biocontainers.pro/registry)
- [sequera containers](https://seqera.io/containers/)

Las imágenes ocupan cientos de MB, así que la caché y las imágenes van a tu carpeta de `/scratch`, nunca al home. Sigue en la sesión interactiva (los nodos de cómputo tienen salida a internet):

```bash
# Sustituye <AAAAMMDD> antes de pegar
mkdir -p /scratch/infec/hpccourse/<AAAAMMDD>_HPC-COURSE_${USER}/ANALYSIS/06-software-management/apptainer_images /scratch/infec/hpccourse/<AAAAMMDD>_HPC-COURSE_${USER}/ANALYSIS/06-software-management/apptainer_cache
export APPTAINER_CACHEDIR=/scratch/infec/hpccourse/<AAAAMMDD>_HPC-COURSE_${USER}/ANALYSIS/06-software-management/apptainer_cache
cd /scratch/infec/hpccourse/<AAAAMMDD>_HPC-COURSE_${USER}/ANALYSIS/06-software-management
apptainer pull apptainer_images/fastp.sif https://depot.galaxyproject.org/singularity/fastp%3A1.0.1--heae3180_0
ls -lh apptainer_images/
```

`apptainer run` hace lo mismo que `exec` pero ejecuta la acción por defecto programada en la imagen, si la tiene; y acepta directamente una URL (descarga la imagen a la caché y la ejecuta):

```bash
apptainer exec https://depot.galaxyproject.org/singularity/fastp%3A1.0.1--heae3180_0 fastp --help
exit     # salimos de la sesión interactiva
```

### 3.3 Lanzar el contenedor con srun

Como ya sabéis, siempre es mejor lanzar los trabajos con `srun` o `sbatch`. Lo mismo aplica para procesos con contenedores. Desde `login01`:

```bash
cd /scratch/infec/hpccourse/<AAAAMMDD>_HPC-COURSE_${USER}/ANALYSIS/06-software-management
srun --partition=test --cpus-per-task=2 --mem=2G --time=00:05:00 apptainer exec \
  --bind /data-ciber/infec/hpccourse/<AAAAMMDD>_HPC-COURSE_${USER},/scratch/infec/hpccourse/<AAAAMMDD>_HPC-COURSE_${USER} \
  /data-ciber/infec/hpccourse/common/images/fastp.sif \
  fastp -w 2 -i /data-ciber/infec/hpccourse/<AAAAMMDD>_HPC-COURSE_${USER}/ANALYSIS/00-reads/virus1_R1.fastq.gz -I /data-ciber/infec/hpccourse/<AAAAMMDD>_HPC-COURSE_${USER}/ANALYSIS/00-reads/virus1_R2.fastq.gz \
        -o trimmed_virus1_R1.fastq.gz -O trimmed_virus1_R2.fastq.gz
ls -lh trimmed_virus1_R*.fastq.gz fastp.html fastp.json
```

Al hacer `--bind <PATH>`, lo que pongamos en `<PATH>` será accesible dentro del contenedor (varias rutas, separadas por comas). En este caso, tu carpeta del proyecto (los datos) y su espejo en `/scratch` (los resultados). `-w 2` le dice a fastp que use las 2 CPU reservadas.

### 3.4 Otros conceptos importantes sobre Apptainer

- Para que la caché vaya siempre a `/scratch`, añade a tu `~/.bashrc` (sustituye `<AAAAMMDD>` por tu fecha antes de pegar) y haz `source ~/.bashrc`:

  ```bash
  export APPTAINER_CACHEDIR=/scratch/infec/hpccourse/<AAAAMMDD>_HPC-COURSE_${USER}/ANALYSIS/06-software-management/apptainer_cache
  ```

- Igual que con micromamba, se pueden compartir imágenes en una carpeta común (como `/data-ciber/infec/hpccourse/common/images`): así todo un grupo usa la misma versión y nadie la descarga dos veces.

- Puedes **configurar y crear tu propio contenedor vía web** fácilmente con [https://seqera.io/containers](https://seqera.io/containers).
  Solo busca cada dependencia y añádela a la lista, luego haz clic en **"Get Container"** y espera a que la imagen esté lista. Una vez completado, puedes usarla con:

  ```bash
  apptainer run <container_url>
  ```

- Si quieres aprender más sobre cómo crear tu propio contenedor, recomendamos revisar la documentación de [apptainer build](https://apptainer.org/docs/user/latest/build_a_container.html) y [docker build](https://docs.docker.com/get-started/workshop/02_our_app/) para conocer todas las especificaciones necesarias.
