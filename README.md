# Tides App
Corona SDK tide app for Ireland

This app runs on IOS and Android. Designed for phones, but can run on tablets
The complete app is available on
IOS: https://itunes.apple.com/ie/app/irish-tides-2016/id1057958920?mt=8
Android: https://play.google.com/store/apps/details?id=com.apptoonz.irishtides2016

There is also a similar app for Solent in England, which is slightly different as it has to contend with double tides.
Normally there are 4 tides per day, and occasionaly 3. In Southampton for example some days there are 10-12 tide points.

The app data is contained in an xml file that ships with the app. See example

    	<day>
    		<id>32</id>
    		<theday>Fri</theday>
    		<thedate>01/01/2016</thedate>
    		<tide1time>03:36</tide1time>
    		<tide1height>3.1</tide1height>
    		<tide2time>09:25</tide2time>
    		<tide2height>1.1</tide2height>
    		<tide3time>15:53</tide3time>
    		<tide3height>3.4</tide3height>
    		<tide4time>21:50</tide4time>
    		<tide4height>0.9</tide4height>
    		<sunrise>08:46</sunrise>
    		<sunset>16:08</sunset>
    		<moon>*</moon>
    		<range>N-2</range>
    	</day>
  
  The app searches through the xml file until it finds the current date, then places 7 days data into an array.
  The array is read to create the tide graph and place the text.
  
  There is a second display, which is a list of tide times and height plus moon phases, sunrie and sunset times.
  The info page contains a link to an inapp purchase that releases the full year of tide data.
  
#Specific Corona SDK information
  The app uses the old Corona STORYBOARD system, as the app has developed over several years. The usual method since 2015 is COMPOSER which does the same job but has more control options.
  
  The inapp purchase is via IAP Badger plugin, which simplifies IAP beautifully. https://github.com/happymongoose/iap_badger
