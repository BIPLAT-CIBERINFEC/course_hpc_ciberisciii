# Curso de iniciación al HPC-CIBER

BiPLAT-CIBERINFEC · adaptado del curso de BU-ISCIII

## Práctica 5: Uso de slurm para gestión de trabajos en el clúster

- [Curso de iniciación al HPC-CIBER](#curso-de-iniciación-al-hpc-ciber)
  - [Práctica 5: Uso de slurm para gestión de trabajos en el clúster](#práctica-5-uso-de-slurm-para-gestión-de-trabajos-en-el-clúster)
    - [Objetivo](#objetivo)
    - [Prerrequisitos](#prerrequisitos)
    - [1. Reservar recursos mínimos con srun desde tu carpeta de proyecto](#1-reservar-recursos-mínimos-con-srun-desde-tu-carpeta-de-proyecto)
    - [2. Probar opciones avanzadas de srun](#2-probar-opciones-avanzadas-de-srun)
    - [3. Enviar trabajos con srun en segundo plano y comprobar con squeue](#3-enviar-trabajos-con-srun-en-segundo-plano-y-comprobar-con-squeue)
    - [4. Gestionar logs y nombre de job](#4-gestionar-logs-y-nombre-de-job)
    - [5. Abrir una sesión interactiva con srun](#5-abrir-una-sesión-interactiva-con-srun)
    - [6. Monitorizar trabajos con squeue y revisar finalizados con sacct](#6-monitorizar-trabajos-con-squeue-y-revisar-finalizados-con-sacct)
    - [7. Cancelar trabajos con scancel](#7-cancelar-trabajos-con-scancel)
    - [8. Copiar datos entre /data-ciber y /scratch usando srun con rsync](#8-copiar-datos-entre-data-ciber-y-scratch-usando-srun-con-rsync)
    - [9. Ejecutar fastqc sobre datos reales en /scratch](#9-ejecutar-fastqc-sobre-datos-reales-en-scratch)
    - [10. Copiar resultados a /data-ciber y limpiar /scratch](#10-copiar-resultados-a-data-ciber-y-limpiar-scratch)
    - [11. Solución de problemas](#11-solución-de-problemas)

### Objetivo

- Comprender cómo reservar recursos con srun
- Diferenciar ejecuciones en lote no interactivas e interactivas
- Monitorizar, cancelar y auditar ejecuciones
- Usar áreas /data-ciber y /scratch de forma correcta

### Prerrequisitos

- Tener acceso al clúster y autenticación por ssh configurada
- Conocer comandos básicos de Linux
- Tener creada tu carpeta de proyecto en `/data-ciber/infec/hpccourse/<AAAAMMDD>_HPC-COURSE_${USER}` con los datos en `RAW` (práctica 4). En los comandos, sustituye `<AAAAMMDD>` por la fecha de tu carpeta.

### 1. Reservar recursos mínimos con srun desde tu carpeta de proyecto

1. Primero vamos a comprobar qué particiones hay en el clúster y cuáles son sus características. Acuérdate de entrar al HPC primero.

```bash
sinfo -o '%P %l %c %m %G'
```

Output:

| Partition      | Timelimit   | Cpus | Memory   | Gres                                  |
|----------------|-------------|------|----------|---------------------------------------|
| long_ciber1    | 10-00:00:00 | 128  | 515186   | (null)                                |
| middle_ciber1  | 2-00:00:00  | 128  | 515186   | (null)                                |
| short_ciber1*  | 12:00:00    | 128  | 515186   | (null)                                |
| test           | 1-00:00:00  | 128  | 515186+  | (null)                                |
| gpu            | 2-00:00:00  | 104  | 515186   | gpu:1                                 |

El `+` de `test` indica que tiene nodos con más memoria: incluye el nodo fat `fn01`, con unos 2 TB (2.058.200 MB). En el HPC-CIBER la partición por defecto es `short_ciber1`; en las prácticas usaremos siempre la partición `test`. SLURM cuenta CPUs lógicas (hilos).

- ¿Qué memoria máxima tenemos por nodo en gb? ¿Cuántas cpus máximas puedo pedir por nodo?

2. Vamos a empezar ejecutando srun specificando CPU, memoria y tiempo.

```bash
cd /data-ciber/infec/hpccourse/<AAAAMMDD>_HPC-COURSE_${USER}/ANALYSIS
# 1 cpu, 1gb memoria ram, 5 minutos tiempo máximo
srun --partition=test --cpus-per-task=1 --mem=1G --time=00:05:00 bash -c "hostname; sleep 60"
# Comprobamos con squeue en otra terminal
squeue -u "$USER" -o "%8i %22j %4t %10u %20q %20P %10Q %5D %11l %11L %50R %10C %c"
# si no usamos -u "$USER" veremos el trabajo de otros usuarios
squeue -o "%8i %22j %4t %10u %20q %20P %10Q %5D %11l %11L %50R %10C %c"
```

3. Repetir pidiendo dos threads y dos gigas.

```bash
srun --partition=test --cpus-per-task=2 --mem=2G --time=00:05:00 bash -c "hostname; sleep 60"
# Comprobamos con squeue en otra terminal. Esta vez filtrando solo por tu usuario
squeue -u "$USER" -o "%8i %22j %4t %10u %20q %20P %10Q %5D %11l %11L %50R %10C %c"
```

- Comprobamos que no se ejecuta en el nodo de acceso login01, sino que se ejecuta en uno de los nodos de cómputo (`cn01`–`cn10`; en `test` también puede ser `fn01`). El hostname va a devolver el nombre del nodo donde se está ejecutando, cada uno tendréis uno diferente. ¿Cuál es el tuyo?

4. ¿Qué ocurre si solicita menos tiempo del necesario?

```bash
srun --partition=test --cpus-per-task=2 --mem=2G --time=00:00:60 bash -c "hostname; sleep 100"
# espera un minuto
```

Output:

```bash
cn01

slurmstepd-cn01: error: *** STEP 4833283.0 ON cn01 CANCELLED AT AAAA-MM-DDThh:mm:ss DUE TO TIME LIMIT ***
srun: Job step aborted: Waiting up to 32 seconds for job step to finish.
srun: error: cn01: task 0: Terminated
```

5. ¿Qué mensaje aparece si excede la memoria solicitada?

```bash
srun --partition=test --time=00:05:00 --mem=300M bash -lc 'python3 -c "import time; b=[]; [ (b.append(bytearray(5*1024*1024)), time.sleep(0.1)) for _ in range(200) ]"'
```

Output:

```bash
slurmstepd-cn01: error: Detected 1 oom_kill event in StepId=4833316.0. Some of the step tasks have been OOM Killed.
srun: error: cn01: task 0: Out Of Memory
```

`[CONFIRMAR: que el HPC-CIBER limita la memoria por trabajo (cgroups) y devuelve este mensaje]`

- Revisemos la información del job con `sacct`

```bash
# <JOBID> es el número de StepId=<JOBID>.0 del mensaje de error anterior (en el ejemplo, 4833316)
sacct -j <JOBID> --format=JobID,State,MaxRSS,ReqMem
# Debido a que el trabajo es muy corto no da tiempo al accounting a recoger la información por lo que no lo veremos aquí.
# en un trabajo más largo sería donde se vería que MaxRSS llega al ReqMem
```

### 2. Probar opciones avanzadas de srun

En esta parte de la práctica vamos a usar opciones más avanzadas de srun para solicitar varios nodos, varias tareas y recursos de GPU cuando existan.

1. Primero podemos comprobar la estructura de los cpus en los nodos de cómputo:

```bash
srun --partition=test bash -c "lscpu | grep -E 'CPU\(|Thread|Core'"
```

Output:

```bash
CPU(s):              128
On-line CPU(s) list: 0-127
Thread(s) per core:  [CONFIRMAR]
Core(s) per socket:  [CONFIRMAR]
NUMA node0 CPU(s):   [CONFIRMAR]
```

`[CONFIRMAR: salida real de lscpu en un nodo de cómputo]`

1. Ejecutar múltiples tareas MPI simuladas.

```bash
srun --partition=test --nodes=1 --ntasks=4 --time=00:10:00 bash -c 'echo Tarea $SLURM_PROCID en $(hostname)'
```

2. Probar dos nodos con dos tareas por nodo.

```bash
srun --partition=test --nodes=2 --ntasks-per-node=1 --time=00:10:00 bash -c 'echo Nodo $(hostname) con tarea $SLURM_PROCID'
```

1. Solicitar una GPU si la partición gpu está disponible.

```bash
srun --partition=gpu --gres=gpu:1 --cpus-per-task=4 --mem=16G --time=00:30:00 nvidia-smi
```

> **Demo del profesor.** Este paso lo ejecuta el profesor en pantalla; los alumnos solo observan. Los nodos GPU (`gpu01`–`gpu02`) son pocos y su uso es aparte de las prácticas. `[CONFIRMAR: que nvidia-smi está en los nodos gpu y que el usuario alumnoNN tiene acceso a la partición gpu]`

### 3. Enviar trabajos con srun en segundo plano y comprobar con squeue

Vamos a probar a dejar procesos ejecutándose y seguir trabajando en la shell.

1. Enviar una tarea en segundo plano que tarde unos minutos.

```bash
srun --partition=test --cpus-per-task=1 --mem=1G --time=00:05:00 bash -c 'sleep 180 && date' &
```

2. Obtener su identificador de trabajo.

```bash
jobs
# jobs devuelve el número de job de bash ([1], [2]...), no el JobID de SLURM.
# El JobID de SLURM es la primera columna de squeue (paso siguiente).
```

3. Consultar su estado en la cola.

```bash
squeue -u $USER -o "%8i %22j %4t %10u %20q %20P %10Q %5D %11l %11L %50R %10C %c"
```

### 4. Gestionar logs y nombre de job

A continuación vamos a aprender a registrar salida a ficheros con el JobID y nombre del trabajo, y a cambiar el directorio de trabajo.

1. Preparar un directorio para pruebas y logs, dentro de `ANALYSIS` de tu proyecto (no en el home).

```bash
mkdir -p /data-ciber/infec/hpccourse/<AAAAMMDD>_HPC-COURSE_${USER}/ANALYSIS/srun_demo/logs
```

2. Lanzar un trabajo que use `--job-name`, `--chdir` y `--output` con `%x` (nombre) y `%j` (JobID).

```bash
srun \
  --partition=test \
  --cpus-per-task=1 \
  --mem=200M \
  --time=00:02:00 \
  --job-name=demo_log \
  --chdir="/data-ciber/infec/hpccourse/<AAAAMMDD>_HPC-COURSE_${USER}/ANALYSIS/srun_demo" \
  --output="/data-ciber/infec/hpccourse/<AAAAMMDD>_HPC-COURSE_${USER}/ANALYSIS/srun_demo/logs/%x_%j.out" \
  bash -lc '
    echo "Job: $SLURM_JOB_NAME (ID: $SLURM_JOB_ID)";
    echo "Host: $(hostname)";
    echo "PWD : $(pwd)";
    echo "Inicio: $(date)";
    sleep 10;
    echo "Fin   : $(date)";
  '
```

3. Verificar que el log existe y contiene la información esperada.

```bash
ls -lh /data-ciber/infec/hpccourse/<AAAAMMDD>_HPC-COURSE_${USER}/ANALYSIS/srun_demo/logs
cat /data-ciber/infec/hpccourse/<AAAAMMDD>_HPC-COURSE_${USER}/ANALYSIS/srun_demo/logs/demo_log_*.out
```

4. Borrar la carpeta con los logs demo.

```bash
rm -r /data-ciber/infec/hpccourse/<AAAAMMDD>_HPC-COURSE_${USER}/ANALYSIS/srun_demo/logs
```

**Notas**

- `--output` acepta patrones de formato: `%j` (JobID), `%x` (JobName), `%N` (nodo), etc.
- La ruta del `--output` debe existir; cree el directorio antes con `mkdir -p`.
- `--chdir` establece el directorio de trabajo para el proceso lanzado.
- Estas opciones son combinables con las usadas en la práctica (`--cpus-per-task`, `--mem`, `--time`, `--nodes`, `--ntasks`, etc.).

### 5. Abrir una sesión interactiva con srun

En esta parte de la práctica vamos a obtener una shell en un nodo de cómputo para pruebas.

1. Solicitar una shell en un nodo de cómputo.

```bash
srun --partition=test --cpus-per-task=2 --mem=2G --time=00:30:00 --pty bash
# comprobar el nodo actual
hostname
# salir de la sesión
exit
```

- El hostname debe ser un nodo de cómputo
- Es recomendable limitar el tiempo y los recursos al mínimo necesario

### 6. Monitorizar trabajos con squeue y revisar finalizados con sacct

1. Obtener un resumen de los trabajos en la cola. Esto lo hemos ido haciendo a lo largo de la práctica.

```bash
squeue -o "%8i %22j %4t %10u %20q %20P %10Q %5D %11l %11L %50R %10C %c"
```

Leyenda del formato:

- %i: JobID (identificador del trabajo)
- %j: JobName (nombre del trabajo)
- %t: State (estado abreviado)
- %u: User (usuario)
- %q: QoS (calidad de servicio, si aplica)
- %P: Partition (partición)
- %Q: Priority (prioridad en cola)
- %D: Nodes (número de nodos asignados)
- %l: TimeLimit (tiempo límite solicitado)
- %L: TimeLeft (tiempo restante)
- %R: Reason/NodeList (motivo si PENDING o lista de nodos si RUNNING)
- %C: CPUs (total de CPUs asignadas al job/step)
- %c: CPUs per task (cpus por tarea, si aplica)

Nota sobre los números: en expresiones como `%8i` o `%22j`, el número indica el ancho de columna (margen/padding) para una salida tabulada más legible. No forma parte del campo en sí.

1. Obtener un resumen de los trabajos terminados.

```bash
sacct -u "$USER" --starttime=today --format=JobID,JobName%20,Partition,AllocCPUS,Elapsed,State,MaxRSS,ExitCode
```

`[CONFIRMAR: que sacct (accounting) está activo en el HPC-CIBER y que el alumno puede ver sus propios trabajos]`

### 7. Cancelar trabajos con scancel

Vamos a lanzar varios trabajos de prueba, cancelar uno específico y luego cancelar el resto, verificando con squeue en cada paso.

1. Lanzar varios trabajos dummy en segundo plano (duermen 180 s) con nombre identificable.

```bash
for i in 1 2 3; do \
  srun --partition=test \
       --cpus-per-task=1 \
       --mem=200M \
       --time=00:05:00 \
       --job-name=demo_cancel_$i \
       bash -lc 'sleep 180' &
done
```

2. Verificar que están en cola/ejecución.

```bash
squeue -u "$USER" -o "%8i %22j %4t %10u %20P %11l %11L %50R"
```

3. Cancelar un trabajo concreto por JobID.

```bash
# Elige un JobID de la salida anterior, p.ej. 1234567
scancel <JOBID>
# Verifica que ese solo desaparece
squeue -u "$USER" -o "%8i %22j %4t %10u %20P %11l %11L %50R"
```

4. Cancelar todos los trabajos restantes del usuario (o solo por nombre).

```bash
# Opción A: cancelar todo lo tuyo (incluye otros trabajos si los hubiera)
scancel -u "$USER"

# Opción B: solo los que coincidan por nombre (p.ej. demo_cancel), se puede cancelar por nombre además de por jobid
scancel -n demo_cancel_1
scancel -n demo_cancel_2
scancel -n demo_cancel_3
```

5. Comprobar que no quedan trabajos demo.

```bash
squeue -u "$USER" -o "%8i %22j %4t %10u %20P %11l %11L %50R" | grep demo_cancel || echo "Sin trabajos demo_cancel"
```

### 8. Copiar datos entre /data-ciber y /scratch usando srun con rsync

Ahora que sabemos usar srun con su parametrización, vamos a aprender a usar los filesystem de /data-ciber y /scratch. Específicamente vamos a copiar de un recurso a otro usando un nodo de cómputo evitando cargar el nodo de acceso.

1. Preparamos las carpetas que vamos a necesitar para el análisis real partiendo de la carpeta que creamos en la práctica anterior.

```bash
# Nos movemos a la carpeta en nuestra carpeta del proyecto dentro del hpc
cd /data-ciber/infec/hpccourse/<AAAAMMDD>_HPC-COURSE_${USER}/ANALYSIS
# Creamos las carpetas que vamos a necesitar
mkdir -p 00-reads 01-fastqc/logs
# vamos a crear un archivo con los nombres de los muestras
ls ../RAW/*.fastq.gz | cut -d "/" -f 3 | cut -d "_" -f 1 | sort -u > samples_id.txt
# Por último creamos enlaces simbólicos para cada muestra de forma homogéne en 00-reads para tenerlo a mano
cd 00-reads
cat ../samples_id.txt | xargs -I % echo "ln -s ../../RAW/%_*1*.fastq.gz %_R1.fastq.gz" | bash
cat ../samples_id.txt | xargs -I % echo "ln -s ../../RAW/%_*2*.fastq.gz %_R2.fastq.gz" | bash
```

1. Copiamos los datos a scratch con un rsync lanzado en un nodo de cómputo.

```bash
srun --partition=test --cpus-per-task=1 --mem=1G --time=00:10:00 \
  rsync -avh /data-ciber/infec/hpccourse/<AAAAMMDD>_HPC-COURSE_${USER}/ /scratch/infec/hpccourse/<AAAAMMDD>_HPC-COURSE_${USER}/
```

Es la misma forma que en la práctica 4 (`srun rsync -avh ORIGEN/ DESTINO/`), con otro origen y destino. Léelo por partes:

| Parte | Qué hace |
|---|---|
| `srun` | Pide a SLURM un hueco en un nodo de cómputo y ejecuta allí lo que va detrás. Mientras dura, tu terminal espera; al acabar, vuelves al nodo de acceso. |
| `--partition=test` | En qué partición. |
| `--cpus-per-task=1 --mem=1G` | Una copia no necesita más: 1 CPU y 1 GB. |
| `--time=00:10:00` | Como mucho 10 minutos. Si se pasa, SLURM la corta. |
| `\` | Solo parte la línea en dos para que se lea mejor. |
| `rsync -avh` | Copia en modo archivo (`-a`: entra en subcarpetas y conserva fechas, permisos y enlaces simbólicos), mostrando qué copia (`-v`) con tamaños legibles (`-h`). |
| `.../<AAAAMMDD>_HPC-COURSE_${USER}/` (origen) | Tu carpeta del proyecto en `/data-ciber`. **La barra final importa:** copia el *contenido* de la carpeta. |
| `/scratch/infec/hpccourse/.../` (destino) | Su espejo en `/scratch`. Si no existe, `rsync` crea solo la última carpeta de la ruta (`/scratch/infec/hpccourse` ya existe). |

### 9. Ejecutar fastqc sobre datos reales en /scratch

Por último vamos a efectuar un ciclo de trabajo completo en scratch.

1. Entrar en la carpeta de trabajo en scratch y localizar el software.

```bash
cd /scratch/infec/hpccourse/<AAAAMMDD>_HPC-COURSE_${USER}/ANALYSIS/
# El software y micromamba se desarrollarán en la siguiente práctica.
# FastQC no está como módulo en el HPC-CIBER: lo usamos desde el entorno común del curso
ls /data-ciber/infec/hpccourse/common/envs/curso_hpc/bin/fastqc
```

`[CONFIRMAR: que FastQC esté instalado en el entorno]`

2. Ejecutar fastqc con srun guardando en RESULTS.

```bash
srun --partition=test --cpus-per-task=2 --mem=4G --time=00:15:00 --chdir /scratch/infec/hpccourse/<AAAAMMDD>_HPC-COURSE_${USER}/ANALYSIS /data-ciber/infec/hpccourse/common/bin/micromamba run -p /data-ciber/infec/hpccourse/common/envs/curso_hpc fastqc -t 2 -o 01-fastqc 00-reads/*.fastq.gz*
```

3. Revisar salida.

```bash
ls 01-fastqc
```

- Deben generarse ficheros HTML y zip por cada fastq

3. Para hacer este análisis hemos utilizado un único comando srun, es decir hemos analizado todas las muestras utilizando un único job, y se ha analizado una detrás de otra. Ahora vamos a lanzarlas todas a la vez en paralelo.

```bash
cat samples_id.txt | xargs -I @@ echo "srun --chdir /scratch/infec/hpccourse/<AAAAMMDD>_HPC-COURSE_${USER}/ANALYSIS --partition=test --job-name fastqc_@@ --cpus-per-task=2 --mem=4G --time=00:15:00 /data-ciber/infec/hpccourse/common/bin/micromamba run -p /data-ciber/infec/hpccourse/common/envs/curso_hpc fastqc -t 2 -o 01-fastqc 00-reads/@@_R1.fastq.gz 00-reads/@@_R2.fastq.gz &" | bash
```

Lo puedes comprobar en otra terminal lanzando:

```bash
watch squeue -u "$USER" -o '%8i %22j %4t %10u %20q %20P %10Q %5D %11l %11L %50R %10C %c'
```

### 10. Copiar resultados a /data-ciber y limpiar /scratch

Una vez terminado el procesamiento tenemos que devolver resultados a almacenamiento persistente y liberar scratch.

1. Copiar resultados a tu directorio de proyecto en /data-ciber.

```bash
srun --partition=test --cpus-per-task=1 --mem=1G --time=00:10:00 \
  rsync -avh /scratch/infec/hpccourse/<AAAAMMDD>_HPC-COURSE_${USER}/ /data-ciber/infec/hpccourse/<AAAAMMDD>_HPC-COURSE_${USER}/
```

2. Limpiar temporal de forma segura.

```bash
cd /data-ciber/infec/hpccourse/<AAAAMMDD>_HPC-COURSE_${USER}
srun --partition=test --cpus-per-task=1 --mem=1G --time=00:10:00 rm -rf /scratch/infec/hpccourse/<AAAAMMDD>_HPC-COURSE_${USER}
```

- Confirmar que el espacio en /scratch disminuye y que los resultados están en /data-ciber

### 11. Solución de problemas

- Mensaje de denegación en nodo de acceso
- Trabajo en estado pendiente prolongado: revise la partición, recursos, límites de proyecto y prioridad
- Error por memoria insuficiente: aumente --mem y revise MaxRSS en sacct
- No hay GPUs disponibles: use la partición correcta (`gpu`) y compruebe gres con sinfo -o '%G'
- Permisos en /scratch o en /data-ciber: verifique propietario, grupo (`hpccourse`) y espacio disponible
