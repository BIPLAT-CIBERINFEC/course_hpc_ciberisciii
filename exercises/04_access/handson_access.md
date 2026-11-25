# Curso de iniciación al HPC-CIBER

BiPLAT-CIBERINFEC · adaptado del curso de BU-ISCIII

## Práctica 4: Acceso y transferencia de datos al clúster

## Índice

- [Curso de iniciación al HPC-CIBER](#curso-de-iniciación-al-hpc-ciber)
  - [Práctica 4: Acceso y transferencia de datos al clúster](#práctica-4-acceso-y-transferencia-de-datos-al-clúster)
  - [Índice](#índice)
    - [Descripción](#descripción)
    - [Notas importantes](#notas-importantes)
    - [Ejercicio 1: Conexión SSH](#ejercicio-1-conexión-ssh)
      - [Opciones de depuración](#opciones-de-depuración)
    - [Ejercicio 2: Exploración del entorno](#ejercicio-2-exploración-del-entorno)
    - [Ejercicio 3: Organización de proyecto](#ejercicio-3-organización-de-proyecto)
    - [Ejercicio 4: Configuración de clave SSH](#ejercicio-4-configuración-de-clave-ssh)
    - [Ejercicio 5: Transferencia de datos](#ejercicio-5-transferencia-de-datos)
      - [Descargar los datos de la práctica en tu ordenador](#descargar-los-datos-de-la-práctica-en-tu-ordenador)
      - [Subir archivos con `scp`](#subir-archivos-con-scp)
      - [Descargar un archivo con `scp`](#descargar-un-archivo-con-scp)
      - [Sincronizar una carpeta con `rsync`](#sincronizar-una-carpeta-con-rsync)
      - [Copiar los datos del curso dentro del HPC con `srun rsync`](#copiar-los-datos-del-curso-dentro-del-hpc-con-srun-rsync)
      - [Sincronizar una carpeta con MobaXterm, WinSCP o FileZilla](#sincronizar-una-carpeta-con-mobaxterm-winscp-o-filezilla)
    - [Ejercicio 6: Verificación de integridad](#ejercicio-6-verificación-de-integridad)

### Descripción

En esta práctica aprenderás a:

- Conectarte al clúster HPC usando SSH.
- Explorar el entorno de trabajo.
- Configurar intercambio de claves SSH para no tener que introducir la contraseña en cada conexión (si el HPC-CIBER lo permite).
- Transferir datos entre tu equipo y el clúster utilizando diferentes herramientas (línea de comandos y programas con interfaz gráfica).
- Verificar la integridad de los ficheros transferidos mediante checksums.
- Construir la estructura de directorios de tu proyecto del curso en `/data-ciber`.

### Notas importantes

- Se accede al nodo de acceso del HPC-CIBER por la consola del portal de Zscaler (PRA) o por `ssh` con el cliente Zscaler (ZCC), en ambos casos a la **IP acabada en `.10`** (la completa se da en clase). La acabada en `.9` es la de administradores.
- **En el nodo de acceso no se lanza nada.** Ahí se editan y organizan ficheros y se envían trabajos. Todo cálculo, y también las copias grandes, va con `srun` o `sbatch`.
- Los datos se organizan en tres espacios:

  - `/hpcciber/home/<usuario>` → configuración y scripts personales pequeños. Poco espacio; no se analiza aquí.
  - `/data-ciber/<área>/<proyecto>` → el proyecto: datos, scripts del análisis, documentación y resultados. Persistente. El del curso es `/data-ciber/infec/hpccourse`.
  - `/scratch/<área>/<proyecto>` → copia de trabajo mientras calculas. Rápido, temporal y compartido por todo CIBER. El del curso es `/scratch/infec/hpccourse`. En el HPC-CIBER se puede escribir desde el nodo de acceso, pero los análisis y las copias se hacen siempre en un nodo de cómputo.
- Flujo de trabajo: `/data-ciber` → `/scratch` (calcular) → resultados a `/data-ciber` → limpiar `/scratch`.
- No almacenar información no relacionada con los cálculos autorizados.

### Ejercicio 1: Conexión SSH

- Lo primero que vamos a hacer es conectarnos al clúster con nuestras credenciales del HPC (no las de Zscaler: son **dos usuarios distintos**).

**Opción 1 (la del curso): consola del portal de Zscaler (PRA).** Entra en el portal con tu correo corporativo y pulsa sobre la consola del servidor de usuarios, la **IP acabada en `.10`**. Te pedirá el usuario y la contraseña del HPC.

**Opción 2: `ssh` desde tu equipo**, con el cliente Zscaler (ZCC) en estado «Authenticated». En Windows, desde la terminal local de MobaXterm (versión instalable); en Linux o macOS, desde la terminal del sistema. La IP completa se da en clase:

```bash
ssh <usuario>@<IP acabada en .10>
exit
```

Output:

```bash
<usuario>@<IP acabada en .10>'s password:
Last login: ...
[<usuario>@login01 ~]$
```

El sistema solicita la contraseña del usuario (no se ve al escribirla). Tras introducirla, accedemos al nodo de acceso, `login01`, donde aparece el `prompt` con nuestro nombre de usuario y la ruta.

#### Opciones de depuración

Si la conexión por `ssh` falla, podemos añadir opciones de depuración:

- **Modo detallado (-v):**

```bash
ssh -v <usuario>@<IP acabada en .10>
exit
```

Muestra información sobre cada paso de la conexión SSH. Útil para identificar problemas de autenticación. Fíjate en las últimas líneas:

```bash
debug1: Connecting to <IP acabada en .10> port 22.
...
<usuario>@<IP acabada en .10>'s password:
Permission denied, please try again.
```

- **Modo muy detallado (-vv o -vvv):** muestra aún más detalles, incluido el intercambio de claves. Útil cuando el problema es la clave pública o el *fingerprint*.

- **Errores típicos en el HPC-CIBER:**

| Mensaje | Causa probable |
|---|---|
| `Connection timed out` | El cliente Zscaler (ZCC) no está conectado o no está «Authenticated» |
| `Permission denied` | Contraseña incorrecta o has usado el usuario de Zscaler en lugar del del HPC |
| `Could not resolve hostname` / `No route to host` | IP mal escrita |
| `Host key verification failed` | Ha cambiado la huella del servidor: avisa al soporte antes de borrar nada en `~/.ssh/known_hosts` |

### Ejercicio 2: Exploración del entorno

- Ahora vamos a familiarizarnos con el nodo de acceso y los recursos disponibles del clúster. Entra de nuevo por la consola del PRA o por `ssh`:

```bash
ssh <usuario>@<IP acabada en .10>
```

- Quiénes somos y a qué grupos pertenecemos:

```bash
whoami
id
groups
```

Output (ejemplo):

```bash
[alumno00@login01 ~]$ whoami
alumno00
[alumno00@login01 ~]$ id
uid=XXXX(alumno00) gid=XXXX(alumno00) groups=XXXX(alumno00),XXXX(hpccourse)
[alumno00@login01 ~]$ groups
alumno00 hpccourse
```

En el HPC-CIBER **cada proyecto es un grupo**: perteneces a `hpccourse`, el grupo del proyecto del curso, y por eso puedes entrar en su carpeta. `[CONFIRMAR formato real de id]`

- Carpetas disponibles en `/`

```bash
pwd
ls -l /
```

Output (resumido):

```bash
/hpcciber/home/alumno00

drwxr-xr-x  ...  data-ciber
drwxr-xr-x  ...  hpcciber
drwxr-xr-x  ...  scratch
...
```

El comando `pwd` muestra la ruta actual: tu home. `ls -l /` muestra los directorios principales; los que nos interesan son `/hpcciber` (donde está tu home), `/data-ciber` y `/scratch`.

- Podemos usar el comando `df` para ver el espacio disponible en cada uno de ellos:

```bash
df -h /hpcciber/home /data-ciber /scratch
```

Output (orientativo, medido el 20/11/2026; cambia cada día):

```bash
Filesystem          Size  Used Avail Use% Mounted on
<servidor>:/...     1.1P   ...   ...  14% /hpcciber/home
<servidor>:/...     1.1P   ...   ...  14% /data-ciber
<servidor>:/...      20T   ...  8.8T  57% /scratch
```

`/hpcciber/home` y `/data-ciber` están en el mismo volumen, así que `df` muestra el espacio de todo el volumen, **no tu cuota**. `/scratch` son 20 TB compartidos por todo CIBER: lo que no estés calculando, fuera.

- `/data-ciber` y `/scratch` se organizan por área CIBER y, dentro, por proyecto:

```bash
ls /data-ciber/
ls /data-ciber/infec/
ls -ld /data-ciber/infec/hpccourse /scratch/infec/hpccourse
```

Output (resumido):

```bash
bbn  er  es  infec  onc  resp  shared
...  hpccourse  <otros proyectos>  ...
drwxrws---  ...  root  hpccourse  ...  /data-ciber/infec/hpccourse
drwxrws---  ...  root  hpccourse  ...  /scratch/infec/hpccourse
```

> ¿Quién tiene permisos en las carpetas del curso? ¿Pertenecemos a ese grupo? Prueba a entrar en la carpeta de otro proyecto: deberías recibir `Permission denied`. Solo ves los proyectos en los que estás dado de alta. `[CONFIRMAR permisos reales de las carpetas]`

- Por último en esta sección vamos a inspeccionar nuestro `.bashrc`:

```bash
cat ~/.bashrc
```

Output ejemplo (vuestro bashrc estará menos configurado):

```bash
# Source global definitions
if [ -f /etc/bashrc ]; then
        . /etc/bashrc
fi

alias si="sinfo -o \"%20P %5D %14F %8z %10m %10d %11l %16f %N\""
alias sq="squeue -o \"%8i %12j %4t %10u %20q %20a %10g %20P %10Q %5D %11l %11L %50R %10C %c\""
alias sa="squeue -u $USER"
alias scratch="srun --partition test --chdir /scratch/infec/hpccourse --pty bash"

export NXF_SINGULARITY_CACHEDIR=/data-ciber/infec/hpccourse/singularity-cache
export LC_ALL="en_US.UTF-8"
```

El archivo .bashrc es un script de configuración que se ejecuta automáticamente cada vez que abrimos una nueva shell interactiva de Bash.

Sirve para personalizar el entorno del usuario: definir variables de entorno, cargar módulos, configurar el prompt, crear alias y funciones, etc. Es de lo poco que sí va en el home.

### Ejercicio 3: Organización de proyecto

- Ahora vamos a crear la estructura de directorios de **tu** proyecto del curso, dentro del proyecto `hpccourse` de `/data-ciber`. Ahí irán tus datos, tus scripts y tus resultados durante todo el curso; el home solo para tu configuración.

```bash
mkdir -p /data-ciber/infec/hpccourse/$(date +%Y%m%d)_HPC-COURSE_${USER}/{RAW,ANALYSIS,RESULTS,DOC,TMP,REFERENCES}
ls -R /data-ciber/infec/hpccourse/$(date +%Y%m%d)_HPC-COURSE_${USER}
```

Output:

```bash
/data-ciber/infec/hpccourse/<AAAAMMDD>_HPC-COURSE_alumno00:
ANALYSIS  DOC  RAW  REFERENCES  RESULTS  TMP
/data-ciber/infec/hpccourse/<AAAAMMDD>_HPC-COURSE_alumno00/ANALYSIS:
/data-ciber/infec/hpccourse/<AAAAMMDD>_HPC-COURSE_alumno00/DOC:
/data-ciber/infec/hpccourse/<AAAAMMDD>_HPC-COURSE_alumno00/RAW:
/data-ciber/infec/hpccourse/<AAAAMMDD>_HPC-COURSE_alumno00/REFERENCES:
/data-ciber/infec/hpccourse/<AAAAMMDD>_HPC-COURSE_alumno00/RESULTS:
/data-ciber/infec/hpccourse/<AAAAMMDD>_HPC-COURSE_alumno00/TMP:
```

`mkdir` en el nodo de acceso está bien: organizar carpetas no es calcular.

| Carpeta | Qué guarda |
|---|---|
| `RAW` | Datos de entrada tal como llegan. No se modifican. |
| `ANALYSIS` | Una subcarpeta por práctica, con sus scripts y logs |
| `RESULTS` | Lo que conservas al final |
| `DOC` | Notas, versiones, decisiones |
| `TMP` | Intermedios que se pueden borrar |
| `REFERENCES` | Genomas, bases de datos |

- Apunta la fecha del nombre de tu carpeta: la usarás en el resto de prácticas.

La organización clara de los proyectos permite localizar fácilmente los datos, compartir con colaboradores y evitar problemas de almacenamiento. En el ejercicio 5 subirás tus datos directamente a `RAW`.

### Ejercicio 4: Configuración de clave SSH

`[CONFIRMAR: que el HPC-CIBER admite autenticación por clave SSH a través de Zscaler; si no, se quita este ejercicio]`

- Ahora vamos a configurar nuestra clave SSH para poder conectarnos sin necesidad de escribir la contraseña en cada acceso (solo para la opción 2, `ssh` desde tu equipo).
- La clave se genera en **tu ordenador** y se copia al clúster. Por lo tanto *salimos del HPC con `exit`*:

```bash
ssh-keygen -t ed25519 -f ~/.ssh/id_ed25519
ssh-copy-id -i ~/.ssh/id_ed25519 <usuario>@<IP acabada en .10>
```

Output:

```bash
Generating public/private ed25519 key pair.
Enter passphrase (empty for no passphrase):
...
Number of keys added: 1
Now try logging into the machine, with:   ssh '<usuario>@<IP acabada en .10>'
```

El comando `ssh-keygen` genera una nueva clave pública/privada en el directorio `~/.ssh/`. Con `ssh-copy-id` copiamos la clave pública al clúster. A partir de este momento, las conexiones SSH se autentican sin pedir la contraseña. La clave privada (`id_ed25519`, sin `.pub`) no se comparte nunca.

### Ejercicio 5: Transferencia de datos

- En este ejercicio vamos a transferir los datos de la práctica a la carpeta `RAW` de tu proyecto (ejercicio 3). Los datos van **directamente al proyecto en `/data-ciber`**, no al home.

| Vía | Para qué | Límite |
|---|---|---|
| Menú de ficheros del portal PRA | Ficheros pequeños, sin instalar nada | 50 MB por fichero |
| `scp` / `rsync` desde tu equipo (opción 2, con ZCC) | Carpetas y datos de secuenciación | — |
| Panel SFTP de MobaXterm | Lo mismo, arrastrando | — |
| `srun rsync` dentro del HPC | Copiar entre espacios del HPC (por ejemplo, los datos del curso a tu `RAW`, o `/data-ciber` ↔ `/scratch`) | — |

Los ficheros de más de 50 MB se suben con `scp` o `rsync`. `[CONFIRMAR: que el límite del PRA es 50 MB por fichero]`

#### Descargar los datos de la práctica en tu ordenador

Desde [Zenodo](https://zenodo.org/records/17207071) o por línea de comandos:

```bash
mkdir -p hpc_course_data
for file in ERR2261314_1.fastq.gz ERR2261314_2.fastq.gz \
            ERR2261315_1.fastq.gz ERR2261315_2.fastq.gz \
            ERR2261318_1.fastq.gz ERR2261318_2.fastq.gz \
            virus1_R1.fastq.gz virus1_R2.fastq.gz \
            virus2_R1.fastq.gz virus2_R2.fastq.gz; do
    wget -c -O "hpc_course_data/$file" \
        "https://zenodo.org/api/records/17207071/files/$file/content" || break
done
```

#### Subir archivos con `scp`

```bash
cd /path/to/where/hpc_course_data_is
scp hpc_course_data/*.fastq.gz <usuario>@<IP acabada en .10>:/data-ciber/infec/hpccourse/<AAAAMMDD>_HPC-COURSE_<usuario>/RAW/
```

Output:

```bash
ERR2261314_1.fastq.gz                      100%   76MB  54.0MB/s   00:01
ERR2261314_2.fastq.gz                      100%   95MB  52.9MB/s   00:01
...
virus2_R2.fastq.gz                         100%   13MB  46.9MB/s   00:00
```

#### Descargar un archivo con `scp`

```bash
scp <usuario>@<IP acabada en .10>:/data-ciber/infec/hpccourse/<AAAAMMDD>_HPC-COURSE_<usuario>/RAW/ERR2261314_1.fastq.gz ./
```

#### Sincronizar una carpeta con `rsync`

```bash
rsync -avz hpc_course_data/ <usuario>@<IP acabada en .10>:/data-ciber/infec/hpccourse/<AAAAMMDD>_HPC-COURSE_<usuario>/RAW/
```

Output:

```bash
sending incremental file list
ERR2261314_1.fastq.gz
...
sent 664,244,980 bytes  received 172 bytes  35,905,143.35 bytes/sec
total size is 663,867,202  speedup is 1.00
```

Si lo repites, `rsync` no vuelve a copiar lo que ya está: solo transfiere lo que falta o ha cambiado.

#### Copiar los datos del curso dentro del HPC con `srun rsync`

Si no puedes subir datos desde tu equipo, el profesor ha dejado los mismos ficheros en `/data-ciber/infec/hpccourse/datos_prueba`. Copiar también es trabajo (lee y escribe en disco y usa la red), así que **no se hace en el nodo de acceso**: se pide un nodo de cómputo con `srun` y la copia se hace allí con `rsync`.

```bash
srun --partition=test --cpus-per-task=1 --mem=1G --time=00:10:00 \
  rsync -avh /data-ciber/infec/hpccourse/datos_prueba/ /data-ciber/infec/hpccourse/<AAAAMMDD>_HPC-COURSE_${USER}/RAW/
```

Este comando lo vas a usar en todo el curso. Léelo por partes:

| Parte | Qué hace |
|---|---|
| `srun` | Pide a SLURM un hueco en un nodo de cómputo y ejecuta allí lo que va detrás. Mientras dura, tu terminal espera; al acabar, vuelves al nodo de acceso. |
| `--partition=test` | En qué partición. |
| `--cpus-per-task=1 --mem=1G` | Una copia no necesita más: 1 CPU y 1 GB. |
| `--time=00:10:00` | Como mucho 10 minutos. Si se pasa, SLURM la corta. |
| `\` | Solo parte la línea en dos para que se lea mejor. |
| `rsync -a` | Copia en modo archivo: entra en subcarpetas y conserva fechas, permisos y enlaces. |
| `-v -h` | Te dice qué copia (`-v`) con tamaños legibles (`-h`). |
| `.../datos_prueba/` | Origen. **La barra final importa:** copia el *contenido* de la carpeta. Sin barra, crearía `RAW/datos_prueba/`. |
| `.../RAW/` | Destino. |

Verás `srun` a fondo en la práctica 5.

#### Sincronizar una carpeta con MobaXterm, WinSCP o FileZilla

- **MobaXterm:** al conectarte por SSH (opción 2), el panel de la izquierda es un explorador SFTP del HPC. Navega a la carpeta `RAW` de tu proyecto y arrastra los ficheros desde tu ordenador.
- **WinSCP o FileZilla:** crea un sitio nuevo con protocolo SFTP, `host = <IP acabada en .10>`, `puerto = 22`, `usuario = <usuario del HPC>`, y arrastra los ficheros del panel izquierdo (tu ordenador) al derecho (el HPC). Las capturas son de la configuración del curso original; cambia el host y el puerto.

![winscp1](winscp1.png)

![filezilla1](filezilla1.png)

Resumen:

- `scp` copia archivos de manera directa.
- `rsync` sincroniza directorios y solo transfiere cambios, lo que ahorra tiempo en transferencias repetidas.
- `srun rsync` es la forma de copiar **dentro** del HPC sin cargar el nodo de acceso.
- MobaXterm, WinSCP y FileZilla ofrecen interfaz gráfica, con arrastrar y soltar.

### Ejercicio 6: Verificación de integridad

- Ahora vamos a comprobar que los archivos no se corrompen al transferirse.

```bash
# En nuestro ordenador local creamos el fichero md5sum de los ficheros
cd /path/to/hpc_course_data
md5sum *.gz > md5sum.md5
scp md5sum.md5 <usuario>@<IP acabada en .10>:/data-ciber/infec/hpccourse/<AAAAMMDD>_HPC-COURSE_<usuario>/RAW/
# Y ya en el HPC (consola del PRA o ssh), comprobamos:
cd /data-ciber/infec/hpccourse/<AAAAMMDD>_HPC-COURSE_<usuario>/RAW
md5sum -c md5sum.md5
```

Output:

```bash
ERR2261314_1.fastq.gz: OK
ERR2261314_2.fastq.gz: OK
ERR2261315_1.fastq.gz: OK
ERR2261315_2.fastq.gz: OK
ERR2261318_1.fastq.gz: OK
ERR2261318_2.fastq.gz: OK
virus1_R1.fastq.gz: OK
virus1_R2.fastq.gz: OK
virus2_R1.fastq.gz: OK
virus2_R2.fastq.gz: OK
```

Output si fallase alguno:

```bash
ERR2261314_1.fastq.gz: OK
ERR2261314_2.fastq.gz: OK
ERR2261315_1.fastq.gz: OK
ERR2261315_2.fastq.gz: OK
ERR2261318_1.fastq.gz: OK
ERR2261318_2.fastq.gz: OK
virus1_R1.fastq.gz: OK
virus1_R2.fastq.gz: FAILED
md5sum: WARNING: 1 computed checksum did NOT match
```

Explicación:
Un checksum es un valor hash generado a partir del contenido de un archivo. Si el archivo se modifica durante la transferencia, el valor no coincide y se detecta el error.
