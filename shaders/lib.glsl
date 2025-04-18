// Pomme Shaders
// Copyright (C) 2025  Wonshtrum
//
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
//
// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.
//
// You should have received a copy of the GNU General Public License
// along with this program.  If not, see <https://www.gnu.org/licenses/>.

#define EXTRUSION_RENDER_DISTANCE 512 // [8 16 32 64 128 256 512]
#define EXTRUSION_ENTITIES 0.5 // [0.1 0.2 0.3 0.4 0.5 0.6 0.7 0.8 0.9 1.0 1.1 1.2 1.3 1.4 1.5 1.6 1.7 1.8 1.9 2.0]
#define EXTRUSION_BLOCKS   1.0 // [0.1 0.2 0.3 0.4 0.5 0.6 0.7 0.8 0.9 1.0 1.1 1.2 1.3 1.4 1.5 1.6 1.7 1.8 1.9 2.0]

#ifdef ENTITY_STAGE
#define EXTRUSION EXTRUSION_ENTITIES
#else
#define EXTRUSION EXTRUSION_BLOCKS
#endif

#define FLAG_FLIPPED 1
#define FLAG_DIAG_FLIPPED 2
#define FLAG_FLAT_LIGHTING 4
#define FLAG_DIAG_LIGHTING 8
#define FLAG_DARK_LIGHTING 16

#define UP vec3(0, 0, 1)

bool has(int x, int f) {
    return (x & f) == f;
}
