#ifdef ENTITY_STAGE
#define EXTRUSION 1
#else
#define EXTRUSION 1
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