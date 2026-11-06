/* Test real compiler layouts and calls without opening a graphics context. */
#include <stddef.h>
#include <string.h>
#include "raygui.h"
#ifdef _WIN32
#define TEST_API __declspec(dllexport)
#else
#define TEST_API __attribute__((visibility("default")))
#endif

TEST_API size_t ClRayguiProbeSize(int type)
{
    switch (type) {
        case 0: return sizeof(bool);
        case 1: return sizeof(Rectangle);
        case 2: return sizeof(Color);
        case 3: return sizeof(Vector2);
        case 4: return sizeof(Vector3);
        case 5: return sizeof(Font);
        case 6: return sizeof(GuiStyleProp);
        default: return 0;
    }
}

TEST_API Rectangle ClRayguiProbeRectangle(Rectangle bounds)
{
    bounds.x += 1; bounds.y += 2;
    bounds.width += 3; bounds.height += 4;
    return bounds;
}

TEST_API Font ClRayguiProbeFont(Font font)
{
    font.baseSize += 1;
    font.texture.id += 1;
    return font;
}

TEST_API Color ClRayguiProbeColor(Color color)
{
    color.r += 1; color.g += 2; color.b += 3; color.a -= 4;
    return color;
}

TEST_API int ClRayguiProbePointers(Rectangle bounds, float *value, bool *active,
                                 Vector2 *scroll, Rectangle *view)
{
    *value += bounds.width;
    *active = !*active;
    scroll->x += bounds.x; scroll->y += bounds.y;
    *view = bounds;
    return RESULT_CHANGED;
}

/* Match controls such as GuiLabel: a struct by value plus nullable text. */
TEST_API int ClRayguiProbeText(Rectangle bounds, const char *text)
{
    return (int)bounds.x + ((text != NULL)? (int)strlen(text) : -1);
}

/* Match slider controls, which marshal two independent text arguments. */
TEST_API int ClRayguiProbeTextPair(Rectangle bounds, const char *left, const char *right)
{
    return (int)bounds.x + ((left != NULL)? (int)strlen(left) : -1)
                        + ((right != NULL)? (int)strlen(right) : -1);
}

/* Exact GuiTextBox argument types, including its by-value C99 bool. */
TEST_API int ClRayguiProbeTextBox(Rectangle bounds, char *text, int textSize, bool editMode)
{
    if (textSize > 1) {
        text[0] = editMode? 'T' : 'F';
        text[1] = '\0';
    }
    return (int)bounds.x + textSize;
}

/* Dropdowns/spinners combine nullable text, mutable pointers and bool values. */
TEST_API int ClRayguiProbeDropdown(Rectangle bounds, const char *text, int *active, bool editMode)
{
    *active += editMode? 1 : -1;
    return (int)bounds.x + ((text != NULL)? (int)strlen(text) : -1);
}

TEST_API bool ClRayguiProbeBool(bool value)
{
    return !value;
}

TEST_API bool ClRayguiProbeBoolWithBounds(Rectangle bounds, bool value)
{
    return (bounds.x > 0)? !value : value;
}

/* Exercise every scalar argument kind used alongside structs in slider calls. */
TEST_API int ClRayguiProbeSlider(Rectangle bounds, const char *left, const char *right,
                                float *value, float minValue, float maxValue)
{
    *value += bounds.width + minValue + maxValue;
    return ((left != NULL)? (int)strlen(left) : -1)
         + ((right != NULL)? (int)strlen(right) : -1);
}
