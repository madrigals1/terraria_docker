#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"

WORLDS_DIR="$PROJECT_DIR/worlds"
ENV_FILE="$PROJECT_DIR/.env"

WORLD_SIZES=("1:Small" "2:Medium" "3:Large")
DIFFICULTIES=("0:Classic" "1:Expert" "2:Master" "3:Journey")
EVIL_TYPES=("0:Random" "1:Corruption" "2:Crimson")

SPECIAL_SEEDS=(
    "for the worthy - Very difficult. Bigger enemy armies, bouncy grenades, statues everywhere, different lava textures, Demon Altars replace chests."
    "not the bees - Jungle-themed world. Most biomes are replaced with honey, hive, and jungle blocks."
    "celebrationmk10 - Celebration-themed. Replaces most blocks with Party Girl-themed blocks, different item drops."
    "the constant - Don't Starve crossover. Unique debuffs and world changes."
    "don't dig up - Everything is inverted. Surface is Hell, Hell is surface."
    "no traps - Ironically removes all traps from the world."
    "get fixed boi - The ultimate challenge. Combines features of all other special seeds."
    "drunkworld - Moon Lord references everywhere, shifted biomes, altered generation."
    "skyblock - Spawns on a floating island with limited resources."
)

SECRET_SEEDS=(
    "monochrome - Entire world is painted gray."
    "negative infinity - Entire world is painted in negative colors."
    "invisible plane - World is echo coated, making most objects hard to see."
    "x-ray vision - World is illuminant coated."
    "mole people - No surface layer, entire world is underground."
    "planetoids - World consists of small planet-like landmasses."
    "such great heights - Surface layer is much higher than normal."
    "waterpark - Significantly more water throughout the world."
    "sandy britches - Desert surface biome."
    "toadstool - Surface is Glowing Mushroom biome."
    "winter is coming - Surface is entirely Tundra biome."
    "save the rainforest - Extra, much larger Living Trees."
    "the care bears movie - Extra floating islands."
    "jagged rocks - Extra chasms and pits throughout the world."
    "abandoned manors - Larger underground cabins."
    "beam me up - Teleporters scattered throughout the world."
    "more traps please - Ironically removes all traps."
    "pumpkin season - World starts with pumpkins everywhere."
    "rainbow road - Rainbow blocks and disco balls throughout."
    "does that sparkle - Hallow on the surface."
    "fish mox - No Corruption or Crimson in the world."
    "purify this - Entire world is infected by evil biome."
    "arachnophobia - No spider caves in the world."
    "bring a towel - Endless rain."
    "hocus pocus - Endless Halloween event."
    "jingle all the way - Endless Christmas event."
    "too easy - World starts in Hardmode."
    "night of the living dead - Graveyards everywhere, starts during Blood Moon."
    "what a horrible night to have a curse - Player spawns underground, burns in sunlight."
    "how did i get here - Random spawn point."
    "royale with cheese - Team-based spawn points."
    "double daring dangers - Dual dungeons, forest surface."
    "i am error - Glitched world generation."
    "truck stop - Poo blocks throughout the world."
    "we don't even test for that - Portal Gun can spawn in any chest."
)

prompt_choice() {
    local prompt="$1"
    shift
    local options=("$@")
    local selected=""

    while true; do
        echo "" >&2
        echo "$prompt" >&2
        for i in "${!options[@]}"; do
            echo "  $((i + 1))) ${options[$i]#*:}" >&2
        done
        echo "" >&2
        read -rp "Enter choice [1-${#options[@]}]: " choice

        if [[ "$choice" =~ ^[0-9]+$ ]] && (( choice >= 1 && choice <= ${#options[@]} )); then
            selected="${options[$((choice - 1))]%%:*}"
            break
        else
            echo "Invalid choice. Please try again."
        fi
    done

    echo "$selected"
}

prompt_value() {
    local prompt="$1"
    local default="${2:-}"
    local value=""

    while true; do
        if [[ -n "$default" ]]; then
            read -rp "$prompt [$default]: " value >&2
        else
            read -rp "$prompt: " value >&2
        fi

        value="${value:-$default}"

        if [[ -n "$value" ]]; then
            echo "$value"
            return
        fi
        echo "This field cannot be empty. Please try again." >&2
    done
}

prompt_multi_select() {
    local prompt="$1"
    shift
    local options=("$@")
    local selected=()
    local toggled=()

    for i in "${!options[@]}"; do
        toggled+=("off")
    done

    while true; do
        echo "" >&2
        echo "$prompt" >&2
        echo "  (enter numbers separated by spaces, e.g. '1 3 5', or press Enter to finish)" >&2
        echo "" >&2
        for i in "${!options[@]}"; do
            local mark=" "
            if [[ "${toggled[$i]}" == "on" ]]; then
                mark="*"
            fi
            echo "  [$mark] $((i + 1))) ${options[$i]%% - *}" >&2
        done
        echo "" >&2
        read -rp "Toggle seeds (or press Enter to continue): " input >&2

        if [[ -z "$input" ]]; then
            break
        fi

        for num in $input; do
            if [[ "$num" =~ ^[0-9]+$ ]] && (( num >= 1 && num <= ${#options[@]} )); then
                idx=$((num - 1))
                if [[ "${toggled[$idx]}" == "on" ]]; then
                    toggled[$idx]="off"
                else
                    toggled[$idx]="on"
                fi
            fi
        done
    done

    for i in "${!options[@]}"; do
        if [[ "${toggled[$i]}" == "on" ]]; then
            selected+=("${options[$i]%% - *}")
        fi
    done

    echo "${selected[@]}"
}

echo "========================================="
echo "       Terraria World Setup"
echo "========================================="
echo ""

WORLD_NAME="$(prompt_value "World name (filename without .wld)")"

SIZE_CHOICE="$(prompt_choice "Select world size:" "${WORLD_SIZES[@]}")"

DIFFICULTY_CHOICE="$(prompt_choice "Select difficulty:" "${DIFFICULTIES[@]}")"

EVIL_CHOICE="$(prompt_choice "Select evil type:" "${EVIL_TYPES[@]}")"

echo "" >&2
echo "=========================================" >&2
echo "  Special Seeds" >&2
echo "  (major world generation changes)" >&2
echo "=========================================" >&2

SPECIAL_SELECTED="$(prompt_multi_select "Toggle special seeds ON:" "${SPECIAL_SEEDS[@]}")"

echo "" >&2
echo "=========================================" >&2
echo "  Secret Seeds" >&2
echo "  (modifiers, can be combined)" >&2
echo "=========================================" >&2

SECRET_SELECTED="$(prompt_multi_select "Toggle secret seeds ON:" "${SECRET_SEEDS[@]}")"

CUSTOM_SEED="$(prompt_value "Additional custom seed (numeric, leave empty to skip)" "")"

SEED_PARTS=()
if [[ -n "$SPECIAL_SELECTED" ]]; then
    SEED_PARTS+=("$SPECIAL_SELECTED")
fi
if [[ -n "$SECRET_SELECTED" ]]; then
    SEED_PARTS+=("$SECRET_SELECTED")
fi
if [[ -n "$CUSTOM_SEED" ]]; then
    SEED_PARTS+=("$CUSTOM_SEED")
fi
SEED="${SEED_PARTS[*]}"

echo ""
echo "========================================="
echo "  Summary"
echo "========================================="
echo "  World name:  $WORLD_NAME"
echo "  Size:        $SIZE_CHOICE"
echo "  Difficulty:  $DIFFICULTY_CHOICE"
echo "  Evil:        $EVIL_CHOICE"
echo "  Seeds:       ${SEED:-none}"
echo "========================================="
echo ""

read -rp "Proceed with world creation? [Y/n]: " confirm
if [[ "${confirm,,}" == "n" ]]; then
    echo "Aborted."
    exit 0
fi

mkdir -p "$WORLDS_DIR"

DOCKER_CMD=(
    docker run -d
    --name terraria-create
    --rm
    -v "$WORLDS_DIR:/root/.local/share/Terraria/Worlds"
    ryshe/terraria:latest
    -world "/root/.local/share/Terraria/Worlds/${WORLD_NAME}.wld"
    -autocreate "$SIZE_CHOICE"
    -difficulty "$DIFFICULTY_CHOICE"
    -evil "$EVIL_CHOICE"
)

if [[ -n "$SEED" ]]; then
    DOCKER_CMD+=(-seed "$SEED")
fi

echo "Creating world..."
sudo "${DOCKER_CMD[@]}"

echo "Waiting for world generation to complete..."
while ! [[ -f "$WORLDS_DIR/${WORLD_NAME}.wld" ]]; do
    if ! sudo docker inspect terraria-create >/dev/null 2>&1; then
        echo "Error: Container exited before world file was created."
        exit 1
    fi
    sleep 2
done

echo "Stopping server..."
sudo docker stop terraria-create >/dev/null 2>&1
sudo docker wait terraria-create >/dev/null 2>&1

if [[ -f "$WORLDS_DIR/${WORLD_NAME}.wld" ]]; then
    echo ""
    echo "World '${WORLD_NAME}.wld' created successfully."

    sed -i "s/^WORLD_FILENAME=.*/WORLD_FILENAME=${WORLD_NAME}.wld/" "$ENV_FILE"

    if ! grep -q "^WORLD_FILENAME=" "$ENV_FILE"; then
        echo "WORLD_FILENAME=${WORLD_NAME}.wld" >> "$ENV_FILE"
    fi

    echo ".env updated with WORLD_FILENAME=${WORLD_NAME}.wld"
else
    echo "Error: World file was not created."
    exit 1
fi
