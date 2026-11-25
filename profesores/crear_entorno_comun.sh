#!/usr/bin/env bash
# Crea el entorno común del curso en el proyecto, para que todos los alumnos lo usen sin instalar nada.
# Lo ejecuta UN profesor, UNA vez, en un nodo de cómputo:
#   srun --partition=test --cpus-per-task=4 --mem=8G --time=01:00:00 bash profesores/crear_entorno_comun.sh
#
# Resultado:
#   $CURSO_COMUN/bin/micromamba         ejecutable compartido
#   $CURSO_COMUN/envs/curso_hpc         el entorno (fastqc, multiqc, seqkit, fastp, spades, nextflow)
#   $CURSO_COMUN/pkgs                   caché de paquetes del profesor
# Los alumnos solo necesitan permiso de lectura; el entorno queda protegido contra escritura.
set -euo pipefail
CURSO_BASE="${CURSO_BASE:-/data-ciber/infec/hpccourse}"   # pruebas: CURSO_BASE=/data-ciber/infec/biplat/hpccourse
CURSO_COMUN="${CURSO_BASE}/comun"
YML="$(cd "$(dirname "$0")" && pwd)/curso_hpc.yml"

if [[ -z "${SLURM_JOB_ID:-}" ]]; then
  echo "Ejecútalo dentro de srun (ver la cabecera), no en el nodo de acceso." >&2; exit 1
fi

mkdir -p "$CURSO_COMUN"/{bin,envs,pkgs}
cd "$CURSO_COMUN"

# 1. micromamba compartido
if [[ ! -x bin/micromamba ]]; then
  curl -Ls https://micro.mamba.pm/api/micromamba/linux-64/latest | tar -xvj -C "$CURSO_COMUN" bin/micromamba
fi
export MAMBA_ROOT_PREFIX="$CURSO_COMUN"
export CONDA_PKGS_DIRS="$CURSO_COMUN/pkgs"
bin/micromamba --version

# 2. Entorno del curso (por ruta, no por nombre: así lo encuentra cualquier usuario)
bin/micromamba create -y -p "$CURSO_COMUN/envs/curso_hpc" -f "$YML"
bin/micromamba env export -p "$CURSO_COMUN/envs/curso_hpc" > "$CURSO_COMUN/curso_hpc.lock.yml"

# 3. Comprobación
for c in fastqc multiqc seqkit fastp spades.py nextflow; do
  printf "%-10s " "$c"; bin/micromamba run -p "$CURSO_COMUN/envs/curso_hpc" "$c" --version 2>&1 | head -1
done

# 4. Permisos: todos leen y ejecutan; nadie escribe en el entorno (tampoco por error)
chmod -R a+rX "$CURSO_COMUN"
chmod -R a-w "$CURSO_COMUN/envs" "$CURSO_COMUN/bin"
echo "Entorno listo en $CURSO_COMUN/envs/curso_hpc. Versiones exactas en $CURSO_COMUN/curso_hpc.lock.yml"
# Para actualizarlo más adelante: chmod -R u+w envs bin, repetir el paso 2 y volver a proteger.
