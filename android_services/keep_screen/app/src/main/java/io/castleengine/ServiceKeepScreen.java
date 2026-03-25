/* -*- tab-width: 4 -*- */

/*
  ----------------------------------------------------------------------------
*/

package io.castleengine;

import android.app.Activity;
import android.view.WindowManager;

/**
 * For this service no need special permission on Android.
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

    private void keepScreenOn()
    {
        getActivity().getWindow().addFlags(WindowManager.LayoutParams.FLAG_KEEP_SCREEN_ON);
    }

    private void keepScreenOff()
    {
        getActivity().getWindow().clearFlags(WindowManager.LayoutParams.FLAG_KEEP_SCREEN_ON);
    }

    @Override
    public boolean messageReceived(String[] parts)
    {
        if (parts.length == 2 && parts[0].equals("keep-screen")) {
            if (parts[1].equals("ON")) {
                keepScreenOn();
            } else if (parts[1].equals("OFF")) {
                keepScreenOff();
            }
            return true;
        } else {
            return false;
        }
    }
}
