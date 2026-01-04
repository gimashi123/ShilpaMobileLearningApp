
const Nav = () => {
  return (
   <div style={{display: 'flex', justifyContent: 'space-between', padding: '10px', borderBottom: '1px solid #ccc'}}>
        <div>
            <a href="/">ශිල්ප</a>
        </div>
   <div style={{display: 'flex', gap: '15px'}}>
        <a href="/">Home</a>
        <a href="/about">About</a>
        <a href="/contact">Contact</a>  
        
   </div>
 
   </div>
  );
};

export default Nav;