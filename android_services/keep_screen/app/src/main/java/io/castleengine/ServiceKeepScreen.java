/* -*- tab-width: 4 -*- */

/*
  ----------------------------------------------------------------------------
*/

package io.castleengine;

import android.Manifest;
import android.view.View;
import android.os.Build;
import android.content.Context;
import android.content.Intent;
import android.app.Activity;
import android.view.WindowManager;

/**
 * service, since this no need special permission on Android.
 */
public class ServiceKeepScreen extends ServiceAbstract
{
    public ServiceKeepScreen(MainActivity activity)
    {
        super(activity);
    }

    public String getName()
    {
        return "keep_screen";
    }

    /* See
       https://developer.android.com/develop/background-work/background-tasks/awake/screen-on
    */

    private void keepScr(boolean enable)
    {
        if (enable) {
            getActivity().getWindow().addFlags(WindowManager.LayoutParams.FLAG_KEEP_SCREEN_ON);
        } else {
            getActivity().getWindow().clearFlags(WindowManager.LayoutParams.FLAG_KEEP_SCREEN_ON);
        }
    }

    @Override
    public boolean messageReceived(String[] parts)
    {
        if (parts.length == 2 && parts[0].equals("keep-screen")) {
            if (parts[1].equals("ON")) {
                keepScr(true);
            } else if (parts[1].equals("OFF")) {
                keepScr(false);
            }
            return true;
        } else {
            return false;
        }
    }
}
