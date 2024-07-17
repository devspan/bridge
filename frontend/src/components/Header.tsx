import React from 'react';
import { Box, Flex, Heading, Spacer, Link, HStack, Icon, useColorModeValue } from "@chakra-ui/react";
import { FaHome, FaSearch, FaTwitter, FaDiscord } from 'react-icons/fa';

const Header: React.FC = () => {
  const bgColor = useColorModeValue('white', 'gray.800');
  const borderColor = useColorModeValue('gray.200', 'gray.700');

  return (
    <Box as="header" width="full" bg={bgColor} p={4} boxShadow="md" borderBottomWidth={1} borderColor={borderColor}>
      <Flex maxWidth="1200px" margin="0 auto" alignItems="center">
        <Heading as="h1" size="lg" color="brand.500">Rupaya Bridge</Heading>
        <Spacer />
        <HStack spacing={4}>
          <Link href="https://rupaya.io" isExternal><Icon as={FaHome} boxSize={6} color="gray.500" _hover={{ color: "brand.500" }} /></Link>
          <Link href="https://explorer.rupaya.io" isExternal><Icon as={FaSearch} boxSize={6} color="gray.500" _hover={{ color: "brand.500" }} /></Link>
          <Link href="https://twitter.com/rupayacoin" isExternal><Icon as={FaTwitter} boxSize={6} color="gray.500" _hover={{ color: "brand.500" }} /></Link>
          <Link href="https://discord.gg/rupaya" isExternal><Icon as={FaDiscord} boxSize={6} color="gray.500" _hover={{ color: "brand.500" }} /></Link>
        </HStack>
      </Flex>
    </Box>
  );
};

export default Header;