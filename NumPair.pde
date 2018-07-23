class NumPair
{
  int x;
  int y;
  
  public NumPair()
  {
    x = 0;
    y = 0;
  }
  
  public NumPair( int x, int y )
  {
    this.x = x;
    this.y = y;
  }
  
  void setCor( int x, int y )
  {
    this.x = x;
    this.y = y;
  }
  
  void copyPair( NumPair equ )
  {
    x = equ.x;
    y = equ.y;
  }
  
  void inc()
  {
    ++x;
    ++y;
  }
}
