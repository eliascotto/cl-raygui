/* Run the real raygui implementation without a window or graphics context.
 * Only input, drawing, screen size and the default font are substituted.
 * raylib's actual UTF-8, glyph lookup, color and collision functions still run.
 * This library must be loaded INSTEAD OF libraygui in a fresh Lisp process.
 */
#include "raylib.h"
#include <string.h>

static Vector2 pointer;
static int buttons, pressedKey, inputCodepoint, drawCalls;
static float wheel;
static Rectangle glyphRects[96];
static GlyphInfo glyphs[96];
static Font testFont;

static Font TestFont(void)
{
    if (testFont.baseSize == 0) {
        for (int i = 0; i < 96; i++) {
            glyphRects[i] = (Rectangle){ 0, 0, 6, 10 };
            glyphs[i].value = i + 32;
            glyphs[i].advanceX = 6;
        }
        testFont = (Font){ .baseSize = 10, .glyphCount = 96,
            .texture = { .id = 1, .width = 128, .height = 128 },
            .recs = glyphRects, .glyphs = glyphs };
    }
    return testFont;
}

static int NextCodepoint(void)
{
    int result = inputCodepoint;
    inputCodepoint = 0;
    return result;
}

#define GUI_POINTER_POSITION pointer
#define GUI_BUTTON_DOWN ((buttons & 1) != 0)
#define GUI_BUTTON_PRESSED ((buttons & 2) != 0)
#define GUI_BUTTON_RELEASED ((buttons & 4) != 0)
#define GUI_BUTTON_PRESSED_MID ((buttons & 8) != 0)
#define GUI_BUTTON_DOWN_ALT 0
#define GUI_SCROLL_DELTA wheel
#define GUI_KEY_DOWN(key) ((key) == pressedKey)
#define GUI_KEY_PRESSED(key) ((key) == pressedKey)
#define GUI_INPUT_KEY NextCodepoint()
#define GetFontDefault() TestFont()
#define GetScreenWidth() 800
#define GetScreenHeight() 600
#define GetClipboardText() ""
#define DrawRectangle(...) ((void)drawCalls++)
#define DrawRectangleGradientEx(...) ((void)drawCalls++)
#define DrawTextCodepoint(...) ((void)drawCalls++)
#define DrawTexturePro(...) ((void)drawCalls++)
#define SetShapesTexture(...) ((void)0)
#define UnloadTexture(...) ((void)0)
#define RAYGUI_IMPLEMENTATION
#include "raygui.h"

RAYGUIAPI void ClRayguiTestFrame(float x, float y, int buttonMask,
                               int key, int codepoint, float scroll)
{
    pointer = (Vector2){ x, y };
    buttons = buttonMask;
    pressedKey = key;
    inputCodepoint = codepoint;
    wheel = scroll;
}

RAYGUIAPI void ClRayguiTestReset(void)
{
    ClRayguiTestFrame(-100, -100, 0, -1, 0, 0);
    guiFont = TestFont();
    memset(guiStyle, 0, sizeof(guiStyle));
    GuiLoadStyleDefault();
    GuiSetState(STATE_NORMAL);
    GuiUnlock();
    GuiSetAlpha(1);
    GuiDisableTooltip();
    GuiSetTooltip(NULL);
    guiControlExclusiveMode = false;
    guiControlExclusiveRec = (Rectangle){ 0 };
    textBoxCursorIndex = 0;
    autoCursorCounter = 0;
    drawCalls = 0;
}

RAYGUIAPI int ClRayguiTestDrawCalls(void) { return drawCalls; }
