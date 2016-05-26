/*
Adrian Eduardo Barrios Lopez 
13550350
Graficación
Proyecto: Reproductor de mp3
25/Mayo/2016
master code */

import controlP5.*;
import ddf.minim.*;
import ddf.minim.analysis.*;
import ddf.minim.effects.*;
import ddf.minim.signals.*;
import ddf.minim.spi.*;
import ddf.minim.ugens.*;

import netP5.*;
import oscP5.*;

import java.util.*;
import java.net.InetAddress;
import javax.swing.*;
import javax.swing.filechooser.FileFilter;
import javax.swing.filechooser.FileNameExtensionFilter;

import org.elasticsearch.action.admin.indices.exists.indices.IndicesExistsResponse;
import org.elasticsearch.action.admin.cluster.health.ClusterHealthResponse;
import org.elasticsearch.action.index.IndexRequest;
import org.elasticsearch.action.index.IndexResponse;
import org.elasticsearch.action.search.SearchResponse;
import org.elasticsearch.action.search.SearchType;
import org.elasticsearch.client.Client;
import org.elasticsearch.common.settings.Settings;
import org.elasticsearch.node.Node;
import org.elasticsearch.node.NodeBuilder;

static String INDEX_NAME = "canciones";
static String DOC_TYPE = "cancion";

ControlP5 selection;
ControlP5 ui;
ControlP5 ui2;
ControlP5 ui3;
ControlP5 mut;
ControlP5 cbars;
ControlP5 cbar;
ControlP5 cbar2;
ControlP5 cpas;
ControlP5 cp5;
ScrollableList list;
Client client;
Node node;
Minim minim;
AudioPlayer song;
AudioMetaData meta;
HighPassSP highpass;
LowPassSP lowpass;
BandPass bandpass;
FFT fft;
int duration = 10;
int timeback = 0;
int millis = 0;
int Progress = 0;
int Volume = 0;
int Hpass;
int Lpass;
int Bpass;
float Vol = 0;
int seg = 0;
int min = 0;
float freq;
boolean selec;
PImage img_mute;
PImage img_unmute;

void setup(){
 size(700, 400);
 
 Settings.Builder settings = Settings.settingsBuilder();

  settings.put("path.data", "esdata");
  settings.put("path.home", "/");
  settings.put("http.enabled", false);
  settings.put("index.number_of_replicas", 0);
  settings.put("index.number_of_shards", 1);
  
  node = NodeBuilder.nodeBuilder()
          .settings(settings)
          .clusterName("mycluster")
          .data(true)
          .local(true)
          .node();
          
  client = node.client();
  
  ClusterHealthResponse r = client.admin().cluster().prepareHealth().setWaitForGreenStatus().get();
  
  IndicesExistsResponse ier = client.admin().indices().prepareExists(INDEX_NAME).get();
  if(!ier.isExists()) {
    client.admin().indices().prepareCreate(INDEX_NAME).get();
  }
  
 selection = new ControlP5(this);
 selection.addButton("selections")
 .setPosition(5,height-31)
 .setSize(45,20);
 
 img_mute = loadImage("mute.png");
 img_unmute = loadImage("unmute.png");
 mut = new ControlP5(this);
 mut.addButton("mute")
 .setValue(0)
 .setPosition(532,height-36)
 .setSize(20,20)
 .setImage(img_unmute)
 .updateSize();
 
 cbars = new ControlP5(this);
 cbars.addSlider("Progress")
 .setPosition(165,height-30)
 .setRange(0,duration)
 .setSize(350,15);
 
 cbars.getController("Progress").setValueLabel("");
 cbars.getController("Progress").setCaptionLabel("");
  
 cbar2 = new ControlP5(this);
 cbar2.addSlider("Volume")
     .setPosition(560,height-29)
     .setSize(110,12)
     .setRange(-30,30)
     .setValue(0)
     .setNumberOfTickMarks(21);
   
 cbar2.getController("Volume").getValueLabel().align(ControlP5.RIGHT, ControlP5.BOTTOM_OUTSIDE).setPaddingY(100);
 cbar2.getController("Volume").getCaptionLabel().align(ControlP5.RIGHT, ControlP5.BOTTOM_OUTSIDE).setPaddingX(-28).setPaddingY(5);
 
 cpas = new ControlP5(this);
 cpas.addSlider("Hpass")
     .setPosition(550,230)
     .setSize(20,100)
     .setRange(0,3000)
     .setValue(0)
     .setNumberOfTickMarks(30);
     
 cpas.addSlider("Lpass")
     .setPosition(650,230)
     .setSize(20,100)
     .setRange(3000,20000)
     .setValue(3000)
     .setNumberOfTickMarks(30);
     
 cpas.addSlider("Bpass")
     .setPosition(600,230)
     .setSize(20,100)
     .setRange(100,1000)
     .setValue(100)
     .setNumberOfTickMarks(30);
     
 cpas.getController("Hpass").getValueLabel().align(ControlP5.RIGHT, ControlP5.BOTTOM_OUTSIDE).setPaddingY(100);
 cpas.getController("Lpass").getValueLabel().align(ControlP5.RIGHT, ControlP5.BOTTOM_OUTSIDE).setPaddingY(100);
 cpas.getController("Bpass").getValueLabel().align(ControlP5.RIGHT, ControlP5.BOTTOM_OUTSIDE).setPaddingY(100);
 
 cp5 = new ControlP5(this);
 list = cp5.addScrollableList("playlist")
            .setPosition(520, 10)
            .setSize(175, 150)
            .setBarHeight(20)
            .setItemHeight(20)
            .setType(ScrollableList.LIST);
            
 loadFiles();
     
 ui = new ControlP5(this);
 PImage[] imgs_a = {loadImage("button_play1.png"),loadImage("button_play2.png"),loadImage("button_play3.png")};
 ui.addButton("play").setValue(0).setPosition(90,height-40).setSize(10,10).setImages(imgs_a).updateSize();
 ui2 = new ControlP5(this);
 PImage[] imgs_b = {loadImage("button_pause1.png"),loadImage("button_pause2.png"),loadImage("button_pause3.png")};
 ui2.addButton("pause").setValue(0).setPosition(126,height-40).setSize(10,10).setImages(imgs_b).updateSize();
 ui3 = new ControlP5(this);
 PImage[] imgs_c = {loadImage("button_stop1.png"),loadImage("button_stop2.png"),loadImage("button_stop3.png")};
 ui3.addButton("stops").setValue(0).setPosition(54,height-40).setSize(10,10).setImages(imgs_c).updateSize();
}

public void draw(){
  background(0);
  fill(150);
  noStroke();
  rect(0,350,width,height);
  rect(517,0,width-515,height);
  fill(255);
  stroke(0);
  text("Title: ", 525, 175);
  text("Author: ", 525, 190);
  text("Duration: ", 525, 205);
  if(minim != null){
  if(mousePressed && mouseX>165 && mouseX<515 && mouseY>370 && mouseY<385){
    if(song.isPlaying() == true){
      song.pause();
      song.play(Progress);
    } else {
      song.cue(Progress);
      millis = Progress;
    }
  }
  if(mousePressed && mouseX>560 && mouseX<670 && mouseY>371 && mouseY<383){
    song.setGain(Volume);
    if(Volume == -30){
      song.mute();
      mut.getController("mute").setImage(img_mute);
    } else {
      song.unmute();
      mut.getController("mute").setImage(img_unmute);
    }
  }
  cbar.getController("Progress").setValue(song.position());
  if(song.position() == duration){
    stops();
  }
  seg = song.position()/1000%60;
  min = song.position()/(60*1000)%60;
  String se = nf(seg, 2);
  String mi = nf(min, 2);
  text(mi+":"+se, 165, height-3); 
  int segd = duration/1000%60;
  int mind = duration/(60*1000)%60;
  String sed = nf(segd, 2);
  String mid = nf(mind, 2);
  text("Duration: "+mid+":"+sed, 525, 205);
  millis = song.position();
  
  timeback = duration - song.position();
  int segres = timeback/1000%60;
  int minres = timeback/(60*1000)%60;
  String sedres = nf(segres, 2);
  String midres = nf(minres, 2);
  text("- "+midres+":"+sedres, 470, height-3);
  
  textSize(12);
  text("Title: " + meta.title(), 525, 175);
  text("Author: " + meta.author(), 525, 190);
  
  if(Volume == -30){
      song.mute();
      mut.getController("mute").setImage(img_mute);
    } else {
      song.unmute();
      mut.getController("mute").setImage(img_unmute);
    }
    
    highpass.setFreq(Hpass);
    lowpass.setFreq(Lpass);
    bandpass.setFreq(Bpass);
    
    fill(0);
    stroke(255);
    fft.forward(song.mix);
    for(int i = 0; i < fft.specSize(); i++){
    float band = fft.getBand(i);
    float vo = 350 - band*50;
    line(i, 350, i, vo);
    }
  }
}

public void selections(){
   JFileChooser jfc = new JFileChooser();
   jfc.setFileFilter(new FileNameExtensionFilter("MP3 File", "mp3"));
   jfc.setMultiSelectionEnabled(true);
   jfc.showOpenDialog(null);
   
   for(File f : jfc.getSelectedFiles()) {
    GetResponse response = client.prepareGet(INDEX_NAME, DOC_TYPE, f.getAbsolutePath()).setRefresh(true).execute().actionGet();
    
    if(minim != null){
      minim.stop();
      minim = new Minim(this);
      song = minim.loadFile(f.getAbsolutePath());
      meta = song.getMetaData();
      iniciar();
    } else {
      minim = new Minim(this);
      song = minim.loadFile(f.getAbsolutePath());
      meta = song.getMetaData();
      iniciar();
    }
    
    if(response.isExists()) {
      continue;
    }
   
   Map<String, Object> doc = new HashMap<String, Object>();
    doc.put("author", meta.author());
    doc.put("title", meta.title());
    doc.put("path", f.getAbsolutePath());
    
    try {
      client.prepareIndex(INDEX_NAME, DOC_TYPE, f.getAbsolutePath())
        .setSource(doc)
        .execute()
        .actionGet();

      addItem(doc);
    } catch(Exception e) {
      e.printStackTrace();
    }
  }
}

public void play(){
 song.play(millis);
}

public void pause(){
 song.pause();
 millis = song.position();
}

public void stops(){
 song.pause();
 millis = 0;
 song.cue(0);
}

public void mute(){
  if(song.isMuted() == true){
    cbar2.getController("Volume").setValue(Vol);
    song.setGain(Volume);
    song.unmute();
    mut.getController("mute").setImage(img_unmute);
  } else {
    Vol = song.getGain();
    cbar2.getController("Volume").setValue(-30);
    song.setGain(Volume);
    song.mute();
    mut.getController("mute").setImage(img_mute);
  }
}

void playlist(int n) {
  Map<String, Object> value = (Map<String, Object>) list.getItem(n).get("value");
  
  if(minim != null){
      minim.stop();
      minim = new Minim(this);
      song = minim.loadFile((String)value.get("path"));
      meta = song.getMetaData();
      iniciar();
    } else {
   minim = new Minim(this);
   song = minim.loadFile((String)value.get("path"));
   meta = song.getMetaData();
   iniciar();
    }
}

void loadFiles() {
  try {
    SearchResponse response = client.prepareSearch(INDEX_NAME).execute().actionGet();

    for(SearchHit hit : response.getHits().getHits()) {
      addItem(hit.getSource());
    }
  } catch(Exception e) {
    e.printStackTrace();
  }
}

void addItem(Map<String, Object> doc) {
  list.addItem(doc.get("author") + " - " + doc.get("title"), doc);
}

void iniciar(){
  fft = new FFT(song.bufferSize(), song.sampleRate());
   highpass = new HighPassSP(300, song.sampleRate());
   song.addEffect(highpass);
   lowpass = new LowPassSP(300, song.sampleRate());
   song.addEffect(lowpass);
   bandpass = new BandPass(300, 300, song.sampleRate());
   song.addEffect(bandpass);
   
   duration = song.length();
   
   cbar = new ControlP5(this);
   cbar.addSlider("Progress")
   .setPosition(165,height-30)
   .setRange(0,duration)
   .setSize(350,15);
   
   cbar.getController("Progress").getValueLabel()
   .align(ControlP5.LEFT, ControlP5.BOTTOM_OUTSIDE).setPaddingX(0).setPaddingY(30);
   cbar.getController("Progress").getCaptionLabel()
   .align(ControlP5.RIGHT, ControlP5.BOTTOM_OUTSIDE).setPaddingX(0).setPaddingY(30);
}