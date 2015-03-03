import de.fhpotsdam.unfolding.*;
import de.fhpotsdam.unfolding.geo.*;
import de.fhpotsdam.unfolding.utils.*;  
import de.fhpotsdam.unfolding.providers.*;
import de.fhpotsdam.unfolding.marker.*;

import beads.*;

UnfoldingMap map;
SimplePointMarker hurricaneMarker;
SimplePointMarker prevMarker;
SimplePointMarker currentMarker;


Table table;
color dotcolor = color(67, 211, 227, 20);
int counter = 0;
int coord;
String id, previd;
float lat, lon, prevlat, prevlon, wind;
int whichHurricane=0;

ArrayList<ArrayList> hurricanes = new  ArrayList<ArrayList>();

AudioContext ac;
WavePlayer wp;
Gain g;
Glide gainGlide;
Glide frequencyGlide;
BiquadFilter filter;

void setup() {
  size(800, 600);
  map = new UnfoldingMap(this, new OpenStreetMap.OSMGrayProvider());
  MapUtils.createDefaultEventDispatcher(this, map);
  map.zoomToLevel(3);
  map.setZoomRange(3, 8); // prevent zooming too far out
  map.panTo(21.0, 31.0);
  frameRate(10);

  smooth();

  //count how many different hurricanes there are.
  table = loadTable("Basin.NA.ibtracs_wmo.v03r06.csv", "header");
  TableRow tempRow = table.getRow(1);  // Gets the second row (index 1)
  previd = tempRow.getString("Serial_Num");
  ArrayList<PVector> hurricane = new ArrayList<PVector>();

  for (TableRow row : table.rows ()) {
    id = row.getString("Serial_Num");

    if (!(id.equals(previd))) {
      ArrayList<PVector> finalHurricane = (ArrayList<PVector>)hurricane.clone();
      hurricanes.add(finalHurricane);
      hurricane.clear();
    }

    lat = row.getFloat("Latitude");
    lon = row.getFloat("Longitude");
    wind = row.getFloat("Wind(WMO)");
    hurricane.add(new PVector(lon,lat, wind));

    previd = id;    //set currentId as previousId
  }
  
  /*set up audio*/
  ac = new AudioContext();
  Noise n = new Noise(ac);
  filter = new BiquadFilter(ac,BiquadFilter.BP_SKIRT,5000.0f,0.5f);
  filter.addInput(n);
  
  gainGlide = new Glide(ac, 0.0, 50);
  g = new Gain(ac, 1, gainGlide);
  g.addInput(filter);
  ac.out.addInput(g);
  ac.start();
  
}

void draw() {
  map.draw();

  ArrayList<PVector> currentHurricane = hurricanes.get(whichHurricane);
  
  PVector firstPoint = currentHurricane.get(0);
  prevlat = firstPoint.y;
  prevlon = firstPoint.x;
  
  for (int i =0; i<currentHurricane.size();i++){
    PVector currentPoint = currentHurricane.get(i);
    lat = currentPoint.y;
    lon = currentPoint.x;

    Location hurricaneLocation = new Location(lat, lon);
    hurricaneMarker = new SimplePointMarker(hurricaneLocation);

    Location prevLocation = new Location(prevlat, prevlon);
    prevMarker = new SimplePointMarker(prevLocation);
    ScreenPosition prevPos = prevMarker.getScreenPosition(map);

    Location currentLocation = new Location(lat, lon);
    currentMarker = new SimplePointMarker(currentLocation);
    ScreenPosition currentPos = currentMarker.getScreenPosition(map);

    stroke(0);
    strokeWeight(map(currentPoint.z,0,100,0,5));
    line(prevPos.x, prevPos.y, currentPos.x, currentPos.y);

    prevlat = lat;
    prevlon = lon;
  }
  PVector currentPoint = currentHurricane.get(coord);
  lat = currentPoint.y;
  lon = currentPoint.x;

  Location hurricaneLocation = new Location(lat, lon);
  hurricaneMarker = new SimplePointMarker(hurricaneLocation);
  ScreenPosition hurricanePos = hurricaneMarker.getScreenPosition(map);

  fill(dotcolor);
  ellipse(hurricanePos.x, hurricanePos.y, map(currentPoint.z,0,100,0,20), map(currentPoint.z,0,100,0,20));
  
  /*audio stuff*/
  
  gainGlide.setValue(map(currentPoint.z,0,100,0,1));
  filter.setFrequency(map(currentPoint.z,0,100,0,2000));
  
  coord++;
  if(coord == currentHurricane.size()){
    coord = 0;
    whichHurricane++;
  }
  if(whichHurricane == hurricanes.size()){
    whichHurricane = 0;
  }
}

void keyPressed(){
  whichHurricane++;
  coord=0;
}
