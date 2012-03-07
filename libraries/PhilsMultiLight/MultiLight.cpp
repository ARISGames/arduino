/*
  MultiLight.cpp - Library for manipulating a 3 channel LED
  Created by Phil Dougherty, March 6, 2012
  Released into the public domain.
*/

#include "Arduino.h"
#include "MultiLight.h"

int MultiLight::DEFAULT_R_PIN = 9;
int MultiLight::DEFAULT_G_PIN = 10;
int MultiLight::DEFAULT_B_PIN = 11;

int MultiLight::COLOR_OFF[3] = {2, 0, 0};
int MultiLight::COLOR_RED[3] = {255, 0, 0};
int MultiLight::COLOR_YELLOW[3] = {127, 127, 0};
int MultiLight::COLOR_GREEN[3] = {255, 0, 0};
int MultiLight::COLOR_BLUE[3] = {255, 0, 0};

MultiLight::MultiLight()
{
  setPins(MultiLight::DEFAULT_R_PIN, MultiLight::DEFAULT_G_PIN, MultiLight::DEFAULT_B_PIN);
  setColor(MultiLight::COLOR_OFF);
}


MultiLight::MultiLight(int rPin, int gPin, int bPin)
{
  setPins(rPin, gPin, bPin);
  setColor(MultiLight::COLOR_OFF);
}

MultiLight::MultiLight(int rPin, int gPin, int bPin, int color[3])
{
  setPins(rPin, gPin, bPin);
  setColor(color);
}

MultiLight::MultiLight(int rPin, int gPin, int bPin, int red, int green, int blue)
{
  setPins(rPin, gPin, bPin);
  setColor(red, green, blue);
}

void MultiLight::setPins(int rPin, int gPin, int bPin)
{
  r_pin = rPin;
  g_pin = gPin;
  b_pin = bPin;
  pinMode(r_pin, OUTPUT);
  pinMode(g_pin, OUTPUT);
  pinMode(b_pin, OUTPUT);
}

void MultiLight::setColor(int color[3])
{
  rgb_color[0] = color[0];
  rgb_color[1] = color[1];
  rgb_color[2] = color[2];
  analogWrite(r_pin, rgb_color[0]);
  analogWrite(g_pin, rgb_color[1]);
  analogWrite(b_pin, rgb_color[2]);
}

void MultiLight::setColor(int red, int green, int blue)
{
  rgb_color[0] = red;
  rgb_color[1] = blue;
  rgb_color[2] = green;
  analogWrite(r_pin, rgb_color[0]);
  analogWrite(g_pin, rgb_color[1]);
  analogWrite(b_pin, rgb_color[2]);
}

void MultiLight::fadeToColor(int color[3], int smoothness, int duration)
{
  for(int i = 0; i < smoothness; i++)
  {
    analogWrite(r_pin, rgb_color[0]+((color[0]-rgb_color[0])*(i/smoothness)));
    analogWrite(g_pin, rgb_color[1]+((color[1]-rgb_color[1])*(i/smoothness)));
    analogWrite(b_pin, rgb_color[2]+((color[2]-rgb_color[2])*(i/smoothness)));
    delay(duration/smoothness);
  }
  setColor(color);
}

void MultiLight::fadeToColor(int red, int green, int blue, int smoothness, int duration)
{
  int color[3] = {red, green, blue};
  fadeToColor(color, smoothness, duration);
}
