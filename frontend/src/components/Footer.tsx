import React from 'react';
import { Box, Flex, Link, Text, VStack, HStack, Icon, useColorModeValue } from "@chakra-ui/react";
import { FaHome, FaSearch, FaTwitter, FaDiscord } from 'react-icons/fa';

const Footer: React.FC = () => {
  const bgColor = useColorModeValue('gray.50', 'gray.800');
  const borderColor = useColorModeValue('gray.200', 'gray.700');

  return (
    <Box as="footer" width="full" bg={bgColor} p={8} mt={16} borderTopWidth={1} borderColor={borderColor}>
      <Flex maxWidth="1200px" margin="0 auto" direction={["column", "row"]} justify="space-between" align="center">
        <VStack align="start" mb={[8, 0]} spacing={4}>
          <Text fontWeight="bold" fontSize="lg" color="brand.500">Quick Links</Text>
          <HStack spacing={4}>
            <Link href="https://rupaya.io" isExternal><Icon as={FaHome} /> Home</Link>
            <Link href="https://explorer.rupaya.io" isExternal><Icon as={FaSearch} /> Explorer</Link>
            <Link href="https://twitter.com/rupayacoin" isExternal><Icon as={FaTwitter} /> Twitter</Link>
            <Link href="https://discord.gg/rupaya" isExternal><Icon as={FaDiscord} /> Discord</Link>
          </HStack>
        </VStack>
        <VStack align={["start", "end"]} spacing={4}>
          <Text fontWeight="bold" fontSize="lg" color="brand.500">Contact</Text>
          <Text>support@rupaya.io</Text>
        </VStack>
      </Flex>
      <Text mt={8} textAlign="center">© 2024 Rupaya Bridge. All rights reserved.</Text>
    </Box>
  );
};

export default Footer;