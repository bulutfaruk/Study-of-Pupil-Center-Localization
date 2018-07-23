class CircleDetector
{
  PImage srcImg;
  
  //Parameters
  int numOfWindows            =    64;//64
  float sizeOfROI             =    4.00f;//1.00
  
  boolean drawROI             =    true;
  boolean drawPupil           =    true;
  
  float maxSumOfEdgeMagnitudes;
  
  int pupilX;
  int pupilY;
  int pupilRadius;
  
  int getPixel( int x, int y )
  {
    if( x < 0 )
      x = 0;
    if( x > inputFrame.width - 1 )
      x = inputFrame.width - 1;
    if( y < 0 )
      y = 0;
    if( y > inputFrame.height - 1 )
      y = inputFrame.height - 1;
      
    return inputFrame.pixels[ y * inputFrame.width + x ];
  }
  
  NumPair rangeDetect( int srcX, int srcY, int massCenterX, int massCenterY, int srcWidth, int srcHeight )
  {
    maxSumOfEdgeMagnitudes  =  0.0f;
    
    int massCenterPixel = getPixel( massCenterX, massCenterY );
    int massCenterIntensity = (int) brightness( massCenterPixel );
    
    pupilX = massCenterX;
    pupilY = massCenterY;
   
    int socketCenterX = srcX + srcWidth/2;
    int socketCenterY = srcY + srcHeight/2;
    
    int centralSocketPixel = getPixel( socketCenterX, socketCenterY );
    int centralSocketIntensity = (int) brightness( centralSocketPixel );
    
    int minX = min(socketCenterX, massCenterX);
    int minY = min(socketCenterY, massCenterY);
    int maxX = max(socketCenterX, massCenterX);
    int maxY = max(socketCenterY, massCenterY);

    int startX = (int) (minX - pupilRadius * sizeOfROI);
    int endX   = (int) (maxX + pupilRadius * sizeOfROI);
    
    int startY = (int) (minY - pupilRadius * sizeOfROI);
    int endY   = (int) (maxY + pupilRadius * sizeOfROI);
    
    if( drawROI )
    {
      stroke( random(256), random(256), random(256) );
      strokeWeight(1);
      rect( startX, startY, endX - startX, endY - startY );
    }
    
    for( int x = startX; x < endX; x++ )
    {
      for( int y = startY; y < endY; y++ )
      {
        float sumOfEdgeMagnitudes = 0.0f;
        int centralPixel = getPixel( x, y );
        int centralIntensity = (int) brightness( centralPixel );
        
        if( centralIntensity < (centralSocketIntensity + massCenterIntensity) / 2.0f + 5.0f )
        {
        
          for( float theta = 0.0f; theta < TWO_PI; theta += TWO_PI / numOfWindows )
          {
            int circEdgePreviousX = (int) (x + floor( cos( theta ) * pupilRadius ) );
            int circEdgePreviousY = (int) (y + floor( sin( theta ) * pupilRadius ) );
            
            int circEdgeNextX     = (int) (x + floor( cos( theta ) * ( pupilRadius + 1 ) ) );
            int circEdgeNextY     = (int) (y + floor( sin( theta ) * ( pupilRadius + 1 ) ) );
            
               
            int kernelPixel_previous = getPixel( circEdgePreviousX, circEdgePreviousY );
            int kernelPixel_next     = getPixel( circEdgeNextX, circEdgeNextY );
            
            
            if( brightness( kernelPixel_next ) > brightness( kernelPixel_previous ) )
            {
              if( brightness( kernelPixel_previous ) > brightness( centralPixel ) )
              {
    
                float edge_magnitude = abs( brightness( kernelPixel_previous ) - brightness( kernelPixel_next ) );
                
                float dist1 = sqrt( (circEdgePreviousX - massCenterX) * (circEdgePreviousX - massCenterX) + (circEdgePreviousY - massCenterY) * (circEdgePreviousY - massCenterY) );
                float dist2 = sqrt( (x - socketCenterX) * (x - socketCenterX) + (y - socketCenterY) * (y - socketCenterY) );
                
                sumOfEdgeMagnitudes += edge_magnitude / ( ( dist1 + dist2 ) + 1.0f );
                
              }
            }
          } 
        }
          
        if( sumOfEdgeMagnitudes > maxSumOfEdgeMagnitudes )
        {
          maxSumOfEdgeMagnitudes = sumOfEdgeMagnitudes;
          
          pupilX = x;
          pupilY = y;
          
        }
        
      }
    }
    
    //Draw final pupil
    if( drawPupil )
    {
      stroke( 255, 0, 0 );
      strokeWeight( 2 );
      ellipse( pupilX, pupilY, pupilRadius * 2, pupilRadius * 2 );
      strokeWeight( 3 );
      point( pupilX, pupilY );
    }
    
    return new NumPair( pupilX, pupilY );
  }
}
