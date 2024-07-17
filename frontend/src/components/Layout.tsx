import React from 'react';
import { Box, Flex } from "@chakra-ui/react"
import Header from './Header';
import Footer from './Footer';
import { ColorModeSwitcher } from "../ColorModeSwitcher"

interface LayoutProps {
  children: React.ReactNode;
}

const Layout: React.FC<LayoutProps> = ({ children }) => {
  return (
    <Flex direction="column" minHeight="100vh">
      <Header />
      <Box flex={1}>
        {children}
      </Box>
      <Footer />
      <ColorModeSwitcher position="fixed" top={4} right={4} />
    </Flex>
  );
};

export default Layout;