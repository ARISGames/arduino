#ifndef MultiLight_h
#define MultiLight_h

#include "Arduino.h"

class MultiLight
{

  public:
    MultiLight();
    MultiLight(int rPin, int gPin, int bPin);    
    MultiLight(int rPin, int gPin, int bPin, int color[3]);
    MultiLight(int rPin, int gPin, int bPin, int red, int green, int blue);
    void setPins(int rPin, int gPin, int bPin);
    void setColor(int color[3]);
    void setColor(int red, int green, int blue);
    void fadeToColor(int color[3], int smoothness, int duration);
    void fadeToColor(int red, int green, int blue, int smoothness, int duration);

    static int DEFAULT_R_PIN;
    static int DEFAULT_G_PIN;
    static int DEFAULT_B_PIN;

    static int COLOR_OFF[3];
    static int COLOR_RED[3];
    static int COLOR_YELLOW[3];
    static int COLOR_GREEN[3];
    static int COLOR_BLUE[3];

  private:
    int r_pin;
    int g_pin;
    int b_pin;
    int rgb_color[3];
};
#endif
