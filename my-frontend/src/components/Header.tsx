type HeaderProps = {
  title: string;
};

const Header = ({ title }: HeaderProps) => {
  return (
    <h1 style={{ color: "#004643" }}>
      {title}
    </h1>
  );
};

export default Header;
