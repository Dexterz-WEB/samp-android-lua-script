
------------------------------------------------------------
-->>                                                    <<--
-->>          __      ____   ______  _____              <<--
-->>          \ \    / /\ \ / /___ \|  __ \             <<--
-->>           \ \  / /  \ V /  __) | |__) |            <<--
-->>            \ \/ /    > <  |__ <|  ___/             <<--
-->>             \  /    / . \ ___) | |                 <<--
-->>              \/    /_/ \_\____/|_|                 <<-- 
-->>                                                    <<--
-->>                                                    <<--
-->>    Discord: https://discord.gg/community123        <<--
-->>    Autor:   @Juquinha123                           <<--
-->>    Apoio:   @ShaBer                                <<--
------------------------------------------------------------

-- Carrega a biblioteca FFI para acesso a funções externas em C
local ffi = require("ffi")

-- Carrega a biblioteca de manipulação de memória
local memory = require 'memory'

-- Carrega a biblioteca de manipulação de bits
local bit = require("bit")

-- Carrega a biblioteca de hooking MonetHook para injetar código em funções existentes
local hook = require('monethook')

-- Carrega a biblioteca GTASA usando FFI para acesso a funções do jogo
local gta = ffi.load("GTASA")

-- Define a estrutura RwV3d para representar um vetor 3D
ffi.cdef[[
typedef struct RwV3d {
    float x, y, z;
} RwV3d;

// Declaração da função em C++ para obter a posição de um osso do personagem
void _ZN4CPed15GetBonePositionER5RwV3djb(void* thiz, RwV3d* posn, uint32_t bone, bool calledFromCam);
]]

-- Definição do módulo community123requeriments para exportar funções e variáveis
local community123requeriments = {}

-- Função para obter a posição de um osso do personagem
function community123requeriments.getBonePosition(ped, bone)
    -- Obtém um ponteiro para o personagem
    local p = ffi.cast('void*', getCharPointer(ped))
    
    -- Cria uma nova estrutura RwV3d para armazenar a posição do osso
    local pos = ffi.new('RwV3d[1]')
    
    -- Chama a função de C++ para obter a posição do osso
    gta._ZN4CPed15GetBonePositionER5RwV3djb(p, pos, bone, false)
    
    -- Retorna as coordenadas x, y, z da posição do osso
    return pos[0].x, pos[0].y, pos[0].z
end

-- Retorna o módulo community123requeriments para ser utilizado em outros scripts
return community123requeriments
